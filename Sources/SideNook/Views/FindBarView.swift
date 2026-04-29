// Sources/SideNook/Views/FindBarView.swift
import SwiftUI
import SwiftTerm

/// Sticky full-width find bar pinned to the top of the terminal area.
/// Mimics the macOS Terminal.app find bar: magnifier + chevron, search field,
/// clear button, prev/next match arrows, "Done" button.
///
/// Search is delegated to SwiftTerm's `findNext`/`findPrevious` which scan the
/// full scrollback, highlight the match via the terminal's selection, and
/// scroll the match into view. The match count is computed by an independent
/// scan over scroll-invariant lines so we can show "N matches" without
/// disturbing the selection state.
struct FindBarView: View {
    @Bindable var state: NookState
    let session: TerminalSession

    @FocusState private var fieldFocused: Bool
    @State private var matchCount: Int = 0
    @State private var hasLandedOnMatch: Bool = false

    private var t: NookTheme { NookTheme(isDark: state.isDark, accent: state.accentColor) }
    private var searchOptions: SearchOptions {
        SearchOptions(caseSensitive: false, regex: false, wholeWord: false)
    }

    var body: some View {
        HStack(spacing: 8) {
            searchField
            navButtons
            doneButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                t.L2
                Rectangle().fill(t.innerHighlight).frame(height: 0.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .overlay(
            Rectangle().fill(t.stroke2).frame(height: 0.5),
            alignment: .bottom
        )
        .onAppear {
            fieldFocused = true
            recomputeAndJump()
        }
        .onChange(of: state.findQuery) { _, _ in recomputeAndJump() }
        .onChange(of: state.findVisible) { _, vis in
            if vis {
                fieldFocused = true
                recomputeAndJump()
            } else {
                session.terminalView.clearSearch()
            }
        }
        .onDisappear {
            session.terminalView.clearSearch()
        }
    }

    // MARK: - Search field (rounded, magnifier + chevron, clear button)

    private var searchField: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(NookType.captionStrong)
                    .foregroundStyle(t.iconFgMute)
                Image(systemName: "chevron.down")
                    .font(NookType.chevronStrong)
                    .foregroundStyle(t.iconFgMute)
            }
            .padding(.leading, 8)

            TextField("", text: $state.findQuery, prompt: Text("Search").foregroundStyle(t.fgMute))
                .textFieldStyle(.plain)
                .font(NookType.labelReg)
                .foregroundStyle(t.fg)
                .focused($fieldFocused)
                .onSubmit { goToNext() }
                .frame(maxWidth: .infinity)

            if !state.findQuery.isEmpty {
                if matchCount > 0 {
                    Text("\(matchCount)")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundStyle(t.fgMute)
                }
                Button {
                    state.findQuery = ""
                    fieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(NookType.labelReg)
                        .foregroundStyle(t.iconFgMute)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
        .frame(height: 22)
        .background(
            RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                .fill(t.L0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                .strokeBorder(fieldFocused ? t.focusBorder : t.stroke3,
                              lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Prev / Next

    private var navButtons: some View {
        HStack(spacing: 0) {
            navButton(icon: "chevron.left", action: goToPrev)
            Rectangle().fill(t.stroke3).frame(width: 0.5, height: 16)
            navButton(icon: "chevron.right", action: goToNext)
        }
        .background(
            RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                .fill(t.L0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                .strokeBorder(t.stroke3, lineWidth: 0.5)
        )
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        let enabled = matchCount > 0
        return Button(action: action) {
            Image(systemName: icon)
                .font(NookType.microStrong)
                .foregroundStyle(enabled ? t.iconFg : t.iconFgMute.opacity(0.5))
                .frame(width: 26, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Done

    private var doneButton: some View {
        Button {
            close()
        } label: {
            Text("Done")
                .font(NookType.label)
                .foregroundStyle(t.fg)
                .padding(.horizontal, 12)
                .frame(height: 22)
                .background(
                    RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                        .fill(t.L0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                        .strokeBorder(t.stroke3, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.escape, modifiers: [])
    }

    // MARK: - Search

    /// Refreshes the match count and jumps to the first match. Called when
    /// the query changes or the bar appears.
    private func recomputeAndJump() {
        let q = state.findQuery

        session.terminalView.clearSearch()
        hasLandedOnMatch = false

        guard !q.isEmpty else {
            matchCount = 0
            return
        }

        matchCount = countMatches(for: q)

        if matchCount > 0 {
            // Land on the first match below current viewport (Terminal-app behaviour:
            // ⌘F starts looking from the visible region forward).
            session.terminalView.findNext(q, options: searchOptions, scrollToResult: true)
            hasLandedOnMatch = true
        }
    }

    private func goToNext() {
        guard !state.findQuery.isEmpty, matchCount > 0 else { return }
        session.terminalView.findNext(state.findQuery, options: searchOptions, scrollToResult: true)
        hasLandedOnMatch = true
    }

    private func goToPrev() {
        guard !state.findQuery.isEmpty, matchCount > 0 else { return }
        session.terminalView.findPrevious(state.findQuery, options: searchOptions, scrollToResult: true)
        hasLandedOnMatch = true
    }

    private func close() {
        session.terminalView.clearSearch()
        state.findVisible = false
        state.findQuery = ""
        matchCount = 0
        hasLandedOnMatch = false
    }

    // MARK: - Match count

    /// Counts case-insensitive substring matches across the entire scrollback by
    /// iterating scroll-invariant lines. Caps at 5000 to keep typing responsive
    /// on huge buffers.
    private func countMatches(for q: String) -> Int {
        let term = session.terminalView.getTerminal()
        let rows = term.rows
        guard rows > 0 else { return 0 }

        // Estimate total line count (visible + scrollback) from scrollThumbsize.
        // thumb = rows / lines.count, so lines.count ≈ rows / thumb.
        let thumb = session.terminalView.scrollThumbsize
        let estimatedTotal: Int = {
            if thumb > 0 && thumb < 1 {
                return max(rows, Int((Double(rows) / Double(thumb)).rounded()) + rows)
            }
            return rows
        }()

        let needle = q.lowercased()
        var count = 0
        let cap = 5000

        for i in 0..<estimatedTotal {
            guard let line = term.getScrollInvariantLine(row: i) else { continue }
            let text = line.translateToString(trimRight: true).lowercased()
            if text.isEmpty || text.count < needle.count { continue }
            var s = text.startIndex
            while let r = text.range(of: needle, range: s..<text.endIndex) {
                count += 1
                if count >= cap { return cap }
                s = r.upperBound
            }
        }
        return count
    }
}
