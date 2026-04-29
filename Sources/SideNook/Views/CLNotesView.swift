// Sources/SideNook/Views/CLNotesView.swift
import SwiftUI
import AppKit

// MARK: - Line number ruler

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?
    var textFont: NSFont
    var gutterFg: NSColor
    var separatorColor: NSColor

    init(textView: NSTextView, font: NSFont, gutterFg: NSColor, separator: NSColor) {
        self.textView = textView
        self.textFont = font
        self.gutterFg = gutterFg
        self.separatorColor = separator
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 36

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
        let attrs: [NSAttributedString.Key: Any] = [
            .font: numFont,
            .foregroundColor: gutterFg
        ]
        let totalGlyphs = layoutManager.numberOfGlyphs

        // Empty document — always show "1"
        guard totalGlyphs > 0 else {
            let str = "1" as NSString
            let sz = str.size(withAttributes: attrs)
            str.draw(
                at: NSPoint(
                    x: ruleThickness - sz.width - 6,
                    y: textView.textContainerInset.height + (numFont.pointSize * 1.4 - sz.height) / 2
                ),
                withAttributes: attrs
            )
            return
        }

        let nsString = textView.string as NSString
        var lineNumber = 1

        layoutManager.enumerateLineFragments(
            forGlyphRange: NSRange(location: 0, length: totalGlyphs)
        ) { [weak self] fragRect, _, _, glyphRange, _ in
            guard let self else { return }
            let charRange = layoutManager.characterRange(
                forGlyphRange: glyphRange, actualGlyphRange: nil
            )
            // Only draw at the start of each logical line (not soft-wrap continuations)
            let isLogicalStart = charRange.location == 0
                || nsString.character(at: charRange.location - 1) == 10 // '\n'
            guard isLogicalStart else { return }

            let fragY = fragRect.minY + textView.textContainerInset.height - visibleRect.minY
            if fragY + fragRect.height > rect.minY && fragY < rect.maxY {
                let str = "\(lineNumber)" as NSString
                let sz = str.size(withAttributes: attrs)
                str.draw(
                    at: NSPoint(
                        x: ruleThickness - sz.width - 6,
                        y: fragY + (fragRect.height - sz.height) / 2
                    ),
                    withAttributes: attrs
                )
            }
            lineNumber += 1
        }

        // Phantom line after a trailing newline (cursor sits on an empty last line)
        if nsString.length > 0, nsString.character(at: nsString.length - 1) == 10 {
            let lastFragRect = layoutManager.lineFragmentRect(
                forGlyphAt: totalGlyphs - 1, effectiveRange: nil
            )
            let extraY = lastFragRect.maxY + textView.textContainerInset.height - visibleRect.minY
            if extraY < rect.maxY {
                let str = "\(lineNumber)" as NSString
                let sz = str.size(withAttributes: attrs)
                str.draw(
                    at: NSPoint(
                        x: ruleThickness - sz.width - 6,
                        y: extraY + (lastFragRect.height - sz.height) / 2
                    ),
                    withAttributes: attrs
                )
            }
        }
    }
}

// MARK: - NSViewRepresentable editor

struct CLNotesEditorView: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let bgColor: NSColor
    let textColor: NSColor
    let gutterFg: NSColor
    let separatorColor: NSColor
    let lineLimit: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        // Explicit TextKit 1 stack — NSRulerView line-number support requires it
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
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
            gutterFg: gutterFg,
            separator: separatorColor
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

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
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
            ruler.gutterFg = gutterFg
            ruler.separatorColor = separatorColor
            ruler.needsDisplay = true
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CLNotesEditorView
        weak var rulerView: LineNumberRulerView?

        init(_ parent: CLNotesEditorView) { self.parent = parent }

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
            rulerView?.needsDisplay = true
        }

        @objc @MainActor func boundsChanged(_ notification: Notification) {
            rulerView?.needsDisplay = true
        }
    }
}

// MARK: - CLNotesView

struct CLNotesView: View {
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.fgMid)

                Text("CL Notes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(t.fgMid)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 0)

                lineCounter

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .medium))
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
        let count = state.clNotes.isEmpty ? 0 : state.clNotes.components(separatedBy: "\n").count
        let atCap = count >= NookState.maxNoteLines
        return Text("\(count)/\(NookState.maxNoteLines)")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(atCap ? t.dotAttn : t.fgMute)
    }

    // MARK: Notes panel

    private var notesPanel: some View {
        VStack(spacing: 0) {
            actionBar

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            CLNotesEditorView(
                text: Binding(
                    get: { state.clNotes },
                    set: { state.clNotes = $0 }
                ),
                font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                bgColor: t.nsNoteBg,
                textColor: t.nsNoteFg,
                gutterFg: t.nsNoteGutterFg,
                separatorColor: t.nsNoteGutterSeparator,
                lineLimit: NookState.maxNoteLines
            )
            .frame(height: 180)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            openInTerminalButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(t.L1)
    }

    private var openInTerminalButton: some View {
        let canSend = state.activeSession != nil && !state.clNotes.isEmpty
        return Button {
            guard canSend, let session = state.activeSession else { return }
            session.send(text: state.clNotes)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "terminal")
                    .font(.system(size: 10, weight: .medium))
                Text("Open in Terminal")
                    .font(.system(size: 11))
            }
            .foregroundStyle(canSend ? t.accentReadable : t.fgMute)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(canSend ? t.accent.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
    }
}
