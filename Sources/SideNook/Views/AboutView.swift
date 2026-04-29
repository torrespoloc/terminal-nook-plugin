// Sources/SideNook/Views/AboutView.swift
import SwiftUI

struct AboutView: View {
    let isDark: Bool
    let onDismiss: () -> Void

    private var t: NookTheme { NookTheme(isDark: isDark) }
    private var bg: Color { t.aboutBg }
    private var fg: Color { t.fg }
    private var fgMid: Color { t.fgMid }
    private var fgMuted: Color { t.fgMute }
    private var dividerColor: Color { t.hoverBg }
    private var codeBg: Color { t.groupBg }
    private var accentColor: Color { t.fgMid }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(NookType.captionBold)
                        .foregroundStyle(fgMuted)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle().fill(t.hoverBg)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // App icon + name
            VStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(NookType.heroXL)
                    .foregroundStyle(accentColor)
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: NookRadius.xl, style: .continuous)
                            .fill(t.L3)
                    )

                Text("SideNook")
                    .font(NookType.heroM)
                    .foregroundStyle(fg)

                Text("A lightweight floating terminal panel for macOS")
                    .font(NookType.labelReg)
                    .foregroundStyle(fgMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)

                Text("Version 1.0.0")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(fgMuted)
            }
            .padding(.top, 4)
            .padding(.bottom, 16)

            Rectangle().fill(dividerColor).frame(height: 0.5)
                .padding(.horizontal, 20)

            // Credits
            VStack(spacing: 8) {
                Text("Created by Jacki")
                    .font(NookType.bodyEmph)
                    .foregroundStyle(fg)
                Text("AI Product Designer")
                    .font(NookType.labelReg)
                    .foregroundStyle(fgMid)
                Text("2026  \u{00B7}  MIT License")
                    .font(NookType.labelReg)
                    .foregroundStyle(fgMid)
                Button(action: {
                    if let url = URL(string: "https://www.linkedin.com/in/jackelinetorres/") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10, weight: .bold))
                        Text("LinkedIn")
                            .font(NookType.label)
                    }
                    .foregroundStyle(fgMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: NookRadius.sm, style: .continuous)
                            .fill(t.hoverBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: NookRadius.sm, style: .continuous)
                                    .strokeBorder(t.stroke2, lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 16)

            Rectangle().fill(dividerColor).frame(height: 0.5)
                .padding(.horizontal, 20)

            // How to update
            VStack(alignment: .leading, spacing: 8) {
                Text("How to Update")
                    .font(NookType.bodyEmph)
                    .foregroundStyle(fg)

                Text("Pull the latest from GitHub and run:")
                    .font(NookType.labelReg)
                    .foregroundStyle(fgMuted)

                Text("make install")
                    .font(NookType.labelMono)
                    .foregroundStyle(fg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: NookRadius.sm, style: .continuous)
                            .fill(codeBg)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Rectangle().fill(dividerColor).frame(height: 0.5)
                .padding(.horizontal, 20)

            Text("SideNook is free and open source software.")
                .font(NookType.labelReg)
                .foregroundStyle(fgMuted)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.bottom, 4)
        }
        .frame(width: 300)
        .background(bg)
    }
}
