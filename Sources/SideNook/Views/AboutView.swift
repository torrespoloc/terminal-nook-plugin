// Sources/SideNook/Views/AboutView.swift
import SwiftUI

struct AboutView: View {
    let isDark: Bool
    let onDismiss: () -> Void

    private var t: NookTheme { NookTheme(isDark: isDark) }
    private var bg: Color { isDark ? NookTheme.darkL3 : Color(white: 0.96) }
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
                        .font(.system(size: 11, weight: .bold))
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
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(t.L3)
                    )

                Text("SideNook")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(fg)

                Text("A lightweight floating terminal panel for macOS")
                    .font(.system(size: 12))
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
            VStack(spacing: 6) {
                Text("Created by Jacki")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(fg)
                Text("AI Product Designer")
                    .font(.system(size: 12))
                    .foregroundStyle(fgMid)
                Text("2026  \u{00B7}  MIT License")
                    .font(.system(size: 12))
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
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(fgMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(t.hoverBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(t.stroke2, lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 14)

            Rectangle().fill(dividerColor).frame(height: 0.5)
                .padding(.horizontal, 20)

            // How to update
            VStack(alignment: .leading, spacing: 6) {
                Text("How to Update")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(fg)

                Text("Pull the latest from GitHub and run:")
                    .font(.system(size: 12))
                    .foregroundStyle(fgMuted)

                Text("make install")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(fg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(codeBg)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle().fill(dividerColor).frame(height: 0.5)
                .padding(.horizontal, 20)

            Text("SideNook is free and open source software.")
                .font(.system(size: 12))
                .foregroundStyle(fgMuted)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.bottom, 4)
        }
        .frame(width: 300)
        .background(bg)
    }
}
