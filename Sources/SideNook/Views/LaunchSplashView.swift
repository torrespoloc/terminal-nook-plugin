// Sources/SideNook/Views/LaunchSplashView.swift
import SwiftUI
import AppKit

struct LaunchSplashView: View {
    static let logoSize: CGFloat = 200
    static let pillWidth: CGFloat = 120
    static let pillHeight: CGFloat = 40

    enum Phase {
        case initial    // offscreen right, pill shape, hidden logo
        case slidIn     // centered, pill shape, hidden logo
        case morphed    // centered, logo shape, visible logo
        case faded      // morphed shape, container faded out
    }

    @State private var phase: Phase = .initial

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear

                ZStack {
                    RoundedRectangle(cornerRadius: shapeCornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: shapeCornerRadius, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                        )
                        .frame(width: shapeWidth, height: shapeHeight)
                        .opacity(pillFillOpacity)

                    if let image = Self.loadLogo() {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Self.logoSize, height: Self.logoSize)
                            .opacity(logoOpacity)
                    }
                }
                .offset(x: xOffset(in: geo.size))
                .opacity(containerOpacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { runSequence() }
        }
    }

    private var shapeWidth: CGFloat {
        switch phase {
        case .initial, .slidIn: return Self.pillWidth
        case .morphed, .faded:  return Self.logoSize
        }
    }

    private var shapeHeight: CGFloat {
        switch phase {
        case .initial, .slidIn: return Self.pillHeight
        case .morphed, .faded:  return Self.logoSize
        }
    }

    private var shapeCornerRadius: CGFloat {
        switch phase {
        case .initial, .slidIn: return Self.pillHeight / 2
        case .morphed, .faded:  return Self.logoSize / 2
        }
    }

    private var pillFillOpacity: Double {
        switch phase {
        case .initial, .slidIn: return 1
        case .morphed, .faded:  return 0
        }
    }

    private var logoOpacity: Double {
        switch phase {
        case .initial, .slidIn: return 0
        case .morphed, .faded:  return 1
        }
    }

    private var containerOpacity: Double {
        phase == .faded ? 0 : 1
    }

    private func xOffset(in screen: CGSize) -> CGFloat {
        switch phase {
        case .initial:                       return screen.width / 2 + Self.pillWidth
        case .slidIn, .morphed, .faded:      return 0
        }
    }

    private func runSequence() {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Start at logo shape, fully transparent, then gentle fade in/out.
            phase = .faded
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.18)) { phase = .morphed }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeIn(duration: 0.15)) { phase = .faded }
            }
            return
        }

        withAnimation(.easeOut(duration: 0.30)) { phase = .slidIn }

        // Overlap morph 50ms before slide finishes — fluid handoff, not a dead beat.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                phase = .morphed
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            withAnimation(.easeIn(duration: 0.15)) { phase = .faded }
        }
    }

    private static func loadLogo() -> NSImage? {
        if let url = Bundle.main.url(forResource: "LaunchLogo", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return nil
    }
}
