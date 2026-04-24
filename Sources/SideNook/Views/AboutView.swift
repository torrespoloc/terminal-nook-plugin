// Sources/SideNook/Views/AboutView.swift
import SwiftUI

struct AboutView: View {
    let isDark: Bool
    let onDismiss: () -> Void

    private var bg: Color {
        isDark ? NookTheme.navy : Color(white: 0.96)
    }
    private var fg: Color {
        isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }
    private var fgMuted: Color {
        isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.45)
    }
    private var dividerColor: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }
    private var codeBg: Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    private var accentColor: Color {
        isDark ? Color.white.opacity(0.60) : Color.black.opacity(0.55)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(fgMuted)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle().fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
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
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    )

                Text("SideNook")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(fg)

                Text("A lightweight floating terminal panel for macOS")
                    .font(.system(size: 13))
                    .foregroundStyle(fgMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)

                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                    .foregroundStyle(fgMuted)
                Text("2024\u{2013}2026  \u{00B7}  MIT License")
                    .font(.system(size: 12))
                    .foregroundStyle(fgMuted)
                Button(action: {
                    if let url = URL(string: "https://www.linkedin.com/in/jacki") {
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.05))
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
                .padding(.vertical, 14)

            Spacer()
        }
        .frame(width: 300)
        .background(bg)
    }
}
