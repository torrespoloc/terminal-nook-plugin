// Sources/SideNook/Views/NotesView.swift
import SwiftUI
import AppKit

// MARK: - Padded text view

/// NSTextView with `isVerticallyResizable = true` calls `setConstrainedFrameSize`
/// during layout using the content's used rect — its height-clamp honours
/// `minSize` inconsistently across layout triggers, so the documentView can
/// collapse to actual content height and the scrollview stops at the last real
/// line. Force the floor here so the gutter's 100-line placeholder area is
/// actually scrollable.
final class PaddedTextView: NSTextView {
    var minDocumentHeight: CGFloat = 0 {
        didSet {
            if abs(oldValue - minDocumentHeight) > 0.5 {
                invalidateIntrinsicContentSize()
                if frame.size.height < minDocumentHeight {
                    super.setFrameSize(NSSize(width: frame.size.width, height: minDocumentHeight))
                }
            }
        }
    }

    override func setConstrainedFrameSize(_ desiredSize: NSSize) {
        var sz = desiredSize
        sz.height = max(sz.height, minDocumentHeight)
        super.setConstrainedFrameSize(sz)
    }

    override func setFrameSize(_ newSize: NSSize) {
        var sz = newSize
        sz.height = max(sz.height, minDocumentHeight)
        super.setFrameSize(sz)
    }
}

// MARK: - Line number ruler

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    var textFont: NSFont
    var gutterBg: NSColor {
        didSet { layer?.backgroundColor = gutterBg.cgColor }
    }
    var gutterFg: NSColor
    var separatorColor: NSColor

    init(textView: NSTextView, font: NSFont, gutterBg: NSColor, gutterFg: NSColor, separator: NSColor, isDark: Bool) {
        self.textView = textView
        self.textFont = font
        self.gutterBg = gutterBg
        self.gutterFg = gutterFg
        self.separatorColor = separator
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 36

        // NSRulerView's default rendering pulls NSColor.controlBackgroundColor,
        // which is light gray under .aqua and dark under .darkAqua. Setting the
        // rulerView's appearance ensures the system color resolves to the right
        // shade for the active theme.
        appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        wantsLayer = true
        layer?.backgroundColor = gutterBg.cgColor

        NotificationCenter.default.addObserver(
            self, selector: #selector(redraw),
            name: NSText.didChangeNotification, object: textView
        )
    }

    required init(coder: NSCoder) { fatalError() }
    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func redraw() { needsDisplay = true }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager else { return }

        // Gutter background inherits from scroll view background — just draw separator
        separatorColor.setFill()
        NSRect(x: ruleThickness - 0.5, y: rect.minY, width: 0.5, height: rect.height).fill()

        let visibleRect = textView.enclosingScrollView?.documentVisibleRect ?? textView.bounds
        let numFont = NSFont.monospacedDigitSystemFont(
            ofSize: max(textFont.pointSize - 1, 9), weight: .regular
        )
        let activeAttrs: [NSAttributedString.Key: Any] = [
            .font: numFont, .foregroundColor: gutterFg
        ]
        let placeholderAttrs = activeAttrs

        let totalGlyphs = layoutManager.numberOfGlyphs
        let topInset = textView.textContainerInset.height
        var lineHeight = layoutManager.defaultLineHeight(for: textFont)
        let nsString = textView.string as NSString

        var nextLineNumber = 1
        var nextY: CGFloat = topInset - visibleRect.minY

        func drawNumber(_ n: Int, atY y: CGFloat, height: CGFloat, attrs: [NSAttributedString.Key: Any]) {
            guard y + height > rect.minY, y < rect.maxY else { return }
            let str = "\(n)" as NSString
            let sz = str.size(withAttributes: attrs)
            str.draw(
                at: NSPoint(x: ruleThickness - sz.width - 6, y: y + (height - sz.height) / 2),
                withAttributes: attrs
            )
        }

        if totalGlyphs > 0 {
            layoutManager.enumerateLineFragments(
                forGlyphRange: NSRange(location: 0, length: totalGlyphs)
            ) { fragRect, _, _, glyphRange, _ in
                let charRange = layoutManager.characterRange(
                    forGlyphRange: glyphRange, actualGlyphRange: nil
                )
                let isLogicalStart = charRange.location == 0
                    || nsString.character(at: charRange.location - 1) == 10
                guard isLogicalStart else { return }
                let fragY = fragRect.minY + topInset - visibleRect.minY
                drawNumber(nextLineNumber, atY: fragY, height: fragRect.height, attrs: activeAttrs)
                nextLineNumber += 1
                nextY = fragY + fragRect.height
                lineHeight = fragRect.height
            }

            // Phantom line after a trailing newline
            if nsString.length > 0, nsString.character(at: nsString.length - 1) == 10 {
                drawNumber(nextLineNumber, atY: nextY, height: lineHeight, attrs: activeAttrs)
                nextLineNumber += 1
                nextY += lineHeight
            }
        }

        // Always fill remaining gutter with placeholder numbers up to 100.
        let placeholderCap = 100
        while nextLineNumber <= placeholderCap, nextY < rect.maxY {
            drawNumber(nextLineNumber, atY: nextY, height: lineHeight, attrs: placeholderAttrs)
            nextLineNumber += 1
            nextY += lineHeight
        }
    }
}

// MARK: - NSViewRepresentable editor

struct NotesEditorView: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let bgColor: NSColor
    let textColor: NSColor
    let gutterBg: NSColor
    let gutterFg: NSColor
    let separatorColor: NSColor
    let lineLimit: Int
    let isDark: Bool
    let isActive: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        // Explicit TextKit 1 stack — NSRulerView line-number support requires it
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        let textView = PaddedTextView(frame: .zero, textContainer: textContainer)
        // Pre-set the minimum document height so the very first layout pass
        // sizes the documentView tall enough — otherwise the scrollview's
        // documentRect locks to ~1 line and later bumps don't propagate.
        let lh = layoutManager.defaultLineHeight(for: font)
        textView.minDocumentHeight = lh * CGFloat(lineLimit + 1) + 8
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainerInset = NSSize(width: 4, height: 4)

        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = bgColor
        textView.insertionPointColor = textColor
        textView.selectedTextAttributes = [.backgroundColor: textColor.withAlphaComponent(0.22)]
        textView.isRichText = false
        textView.isEditable = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.focusRingType = .none
        textView.string = text

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = bgColor
        scrollView.drawsBackground = true
        scrollView.focusRingType = .none
        scrollView.documentView = textView

        let ruler = LineNumberRulerView(
            textView: textView,
            font: font,
            gutterBg: gutterBg,
            gutterFg: gutterFg,
            separator: separatorColor,
            isDark: isDark
        )
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsChanged(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        context.coordinator.rulerView = ruler
        context.coordinator.padDocumentToMinLines(textView: textView)

        // Auto-focus on first appearance so the user can type immediately.
        DispatchQueue.main.async { [weak textView] in
            textView?.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if isActive, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async { [weak textView] in
                textView?.window?.makeFirstResponder(textView)
            }
        }
        if textView.string != text {
            let ranges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = ranges
        }
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = bgColor
        textView.insertionPointColor = textColor
        scrollView.backgroundColor = bgColor
        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.textFont = font
            ruler.gutterBg = gutterBg
            ruler.gutterFg = gutterFg
            ruler.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
            context.coordinator.padDocumentToMinLines(textView: textView)
            ruler.separatorColor = separatorColor
            ruler.needsDisplay = true
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NotesEditorView
        weak var rulerView: LineNumberRulerView?

        init(_ parent: NotesEditorView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let lines = textView.string.components(separatedBy: "\n")
            if lines.count <= parent.lineLimit {
                parent.text = textView.string
            } else {
                let clamped = lines.prefix(parent.lineLimit).joined(separator: "\n")
                let cursorLoc = min(textView.selectedRange.location, clamped.utf16.count)
                textView.string = clamped
                textView.setSelectedRange(NSRange(location: cursorLoc, length: 0))
                parent.text = clamped
            }
            padDocumentToMinLines(textView: textView)
            rulerView?.needsDisplay = true
        }

        @objc @MainActor func boundsChanged(_ notification: Notification) {
            rulerView?.needsDisplay = true
        }

        /// Sets the textView's minSize so the documentView stays at least 100 lines
        /// tall even when actual content is shorter. NSTextView's vertical-resize
        /// pass honours minSize, so the scrollview always lets the user scroll
        /// through the full 100-line gutter.
        func padDocumentToMinLines(textView: NSTextView) {
            let placeholderCap = CGFloat(parent.lineLimit)
            let lineHeight = textView.layoutManager?.defaultLineHeight(for: parent.font)
                ?? parent.font.ascender + abs(parent.font.descender) + parent.font.leading
            let topInset = textView.textContainerInset.height
            // +1 line of trailing buffer so line 100 fully clears the visible
            // bottom at max scroll instead of requiring an overscroll push.
            let minHeight = lineHeight * (placeholderCap + 1) + topInset * 2
            if let padded = textView as? PaddedTextView {
                padded.minDocumentHeight = minHeight
            }
        }
    }
}

// MARK: - NotesView

struct NotesView: View {
    @Bindable var state: NookState

    var showsTrigger: Bool = true

    private var t: NookTheme { state.theme }

    var body: some View {
        Group {
            if showsTrigger {
                VStack(spacing: 0) {
                    triggerRow
                    if state.showNotes {
                        Rectangle().fill(t.stroke1).frame(height: 0.5)
                        notesPanel
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.easeOut(duration: 0.15), value: state.showNotes)
            } else {
                notesPanel
                    .frame(width: 220)
            }
        }
    }

    // MARK: Trigger row

    private var triggerRow: some View {
        Button {
            state.showNotes.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(NookType.label)
                    .foregroundStyle(t.fgMid)

                Text("Notes")
                    .font(NookType.body)
                    .foregroundStyle(t.fgMid)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 0)

                lineCounter

                Image(systemName: "chevron.down")
                    .font(NookType.chevron)
                    .foregroundStyle(t.fgMute)
                    .rotationEffect(.degrees(state.showNotes ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: state.showNotes)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var lineCounter: some View {
        let count = state.Notes.isEmpty ? 0 : state.Notes.components(separatedBy: "\n").count
        let atCap = count >= NookState.maxNoteLines
        return Text("\(count)/\(NookState.maxNoteLines)")
            .font(NookType.microMono)
            .foregroundStyle(atCap ? t.dotAttn : t.fgMute)
    }

    // MARK: Notes panel

    private var notesPanel: some View {
        VStack(spacing: 0) {
            actionBar

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            NotesEditorView(
                text: Binding(
                    get: { state.Notes },
                    set: { state.Notes = $0 }
                ),
                font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                bgColor: t.nsNoteBg,
                textColor: t.nsNoteFg,
                gutterBg: t.nsNoteGutterBg,
                gutterFg: t.nsNoteGutterFg,
                separatorColor: t.nsNoteGutterSeparator,
                lineLimit: NookState.maxNoteLines,
                isDark: state.isDark,
                isActive: state.showNotes
            )
            .frame(height: 180)
            .clipped()
            .padding(.bottom, 8)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            openAsTabButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(t.L1)
    }

    private var openAsTabButton: some View {
        Button {
            state.openNotesTab()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(NookType.micro)
                Text("Open as Tab")
                    .font(NookType.caption)
            }
            .foregroundStyle(t.accentReadable)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                    .fill(t.accentTint)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full-tab notes view

/// Shown in the panel content area when `state.notesTabActive` is true.
/// Replaces the terminal with a full-size notes editor.
struct NotesTabFullView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            NotesEditorView(
                text: Binding(
                    get: { state.Notes },
                    set: { state.Notes = $0 }
                ),
                font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                bgColor: t.nsNoteBg,
                textColor: t.nsNoteFg,
                gutterBg: t.nsNoteGutterBg,
                gutterFg: t.nsNoteGutterFg,
                separatorColor: t.nsNoteGutterSeparator,
                lineLimit: NookState.maxNoteLines,
                isDark: state.isDark,
                isActive: state.notesTabActive
            )
        }
        .background(Color(t.nsNoteBg))
        .clipShape(RoundedRectangle(cornerRadius: NookRadius.lg, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(NookType.label)
                .foregroundStyle(t.fgMid)
            Text("My Notes")
                .font(NookType.body)
                .foregroundStyle(t.fgMid)
            Spacer(minLength: 0)
            let count = state.Notes.isEmpty ? 0 : state.Notes.components(separatedBy: "\n").count
            let atCap = count >= NookState.maxNoteLines
            Text("\(count)/\(NookState.maxNoteLines)")
                .font(NookType.microMono)
                .foregroundStyle(atCap ? t.dotAttn : t.fgMute)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(t.L1)
    }
}
