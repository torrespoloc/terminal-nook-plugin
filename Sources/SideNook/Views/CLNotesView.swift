// Sources/SideNook/Views/CLNotesView.swift
import SwiftUI

struct CLNotesView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        VStack(spacing: 0) {
            triggerRow

            if state.showNotes {
                Rectangle().fill(t.stroke1).frame(height: 0.5)
                notesPanel
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: state.showNotes)
    }

    // MARK: - Trigger row

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

    // MARK: - Notes panel

    private var notesPanel: some View {
        TextEditor(text: Binding(
            get: { state.clNotes },
            set: { newValue in
                let lines = newValue.components(separatedBy: "\n")
                if lines.count <= NookState.maxNoteLines {
                    state.clNotes = newValue
                } else {
                    state.clNotes = lines.prefix(NookState.maxNoteLines).joined(separator: "\n")
                }
            }
        ))
        .font(.system(size: 12, design: .monospaced))
        .foregroundStyle(t.fg)
        .scrollContentBackground(.hidden)
        .background(t.L1)
        .frame(height: 180)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}
