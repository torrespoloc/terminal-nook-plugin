// Sources/SideNook/Theme.swift
import SwiftUI
import AppKit

struct NookTheme {
    let isDark: Bool
    private let _accent: Color?

    init(isDark: Bool, accent: Color? = nil) {
        self.isDark = isDark
        self._accent = accent
    }

    // ── Dark mode: absolute hex (NOT opacity over transparent).
    // Opacity-based layers composite over the NSPanel's clear background
    // and render as near-black. Absolute values are required.
    //
    // L0 #1d1e24  terminal background (deepest)
    // L1 #151720  panel shell
    // L2 #1d2030  nav bar / sidebar card
    // L3 #262a3d  settings popover / active tab

    static let darkL0 = Color(red: 0.114, green: 0.118, blue: 0.141) // #1d1e24
    static let darkL1 = Color(red: 0.082, green: 0.090, blue: 0.125) // #151720
    static let darkL2 = Color(red: 0.114, green: 0.125, blue: 0.188) // #1d2030
    static let darkL3 = Color(red: 0.149, green: 0.165, blue: 0.239) // #262a3d

    // ── Elevation layers ──────────────────────────────────────────────
    var L0: Color { isDark ? Self.darkL0 : Color(white: 0.965, opacity: 0.98) }   // light: rgba(246,246,246,0.98)
    var L1: Color { isDark ? Self.darkL1 : Color.black.opacity(0.025) }            // light: rgba(0,0,0,0.025)
    var L2: Color { isDark ? Self.darkL2 : Color.white.opacity(0.62) }             // light: rgba(255,255,255,0.62)
    var L3: Color { isDark ? Self.darkL3 : Color.white.opacity(0.95) }             // light: rgba(255,255,255,0.95)

    // ── Borders / strokes ─────────────────────────────────────────────
    var stroke0: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.14) }
    var stroke1: Color { isDark ? .white.opacity(0.06) : .black.opacity(0.06) }
    var stroke2: Color { isDark ? .white.opacity(0.10) : .black.opacity(0.08) }
    var stroke3: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.12) }

    // ── Foreground ────────────────────────────────────────────────────
    var fg:     Color { isDark ? Color(red: 0.922, green: 0.933, blue: 0.961).opacity(0.92)
                               : Color.black.opacity(0.88) }
    var fgMid:  Color { isDark ? Color(red: 0.922, green: 0.933, blue: 0.961).opacity(0.66)
                               : Color.black.opacity(0.62) }
    var fgMute: Color { isDark ? Color(red: 0.784, green: 0.804, blue: 0.863).opacity(0.45)
                               : Color.black.opacity(0.42) }

    // ── Highlights ────────────────────────────────────────────────────
    var innerHighlight: Color { isDark ? .white.opacity(0.06) : .white.opacity(0.90) }

    // ── Accent ────────────────────────────────────────────────────────
    // `accent` is the user's literal pick — used for swatches/previews where
    // they need to see exactly what they chose.
    // `accentReadable` is theme-adjusted to meet WCAG contrast on the active
    // surface — used for text and control fills.
    var accent: Color {
        if let a = _accent { return a }
        return isDark ? Color(red: 0.208, green: 0.816, blue: 0.498)
                      : Color(red: 0.11,  green: 0.44,  blue: 0.23)
    }

    /// Accent clamped to a contrast-safe luminance for the active theme.
    /// Light mode: lightness ≤ 0.40 (≥4.5:1 on light surfaces).
    /// Dark mode:  lightness ≥ 0.62 (≥4.5:1 on dark surfaces).
    var accentReadable: Color {
        let target: ClosedRange<CGFloat> = isDark ? 0.62...1.0 : 0.0...0.40
        return Self.clampLightness(of: accent, to: target)
    }

    private static func clampLightness(of color: Color, to range: ClosedRange<CGFloat>) -> Color {
        guard let c = NSColor(color).usingColorSpace(.sRGB) else { return color }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        // HSB brightness ≈ HSL lightness for our purposes (cheap, no full conversion).
        let clamped = min(max(b, range.lowerBound), range.upperBound)
        return Color(NSColor(hue: h, saturation: s, brightness: clamped, alpha: a))
    }

    // ── Terminal background ───────────────────────────────────────────
    var termBg: Color { isDark ? Color(red: 0.114, green: 0.118, blue: 0.141)
                               : Color(red: 0.961, green: 0.961, blue: 0.957) }

    // ── Control colours ───────────────────────────────────────────────
    var groupBg: Color { isDark ? Color.black.opacity(0.15) : Color.black.opacity(0.04) }
    var danger:  Color { isDark ? Color(red: 0.957, green: 0.627, blue: 0.627)
                                : Color.red.opacity(0.80) }

    // ── Hover / pressed surfaces (use these instead of inline opacity literals) ──
    var hoverBg:        Color { isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    var pressedBg:      Color { isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.10) }
    var glassBg:        Color { isDark ? Color.black.opacity(0.55) : Color.white.opacity(0.75) }
    var glassBgHover:   Color { isDark ? Color.black.opacity(0.75) : Color.white.opacity(0.92) }
    var arrowBg:        Color { isDark ? Color(white: 0.20) : Color(white: 0.96) }
    var arrowBgHover:   Color { isDark ? Color(white: 0.28) : Color(white: 0.90) }
    var iconFg:         Color { isDark ? Color.white.opacity(0.70) : Color.black.opacity(0.60) }
    var iconFgMute:     Color { isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.45) }
    var scrim:          Color { isDark ? Color.black.opacity(0.70) : Color.white.opacity(0.80) }
    var defaultAccent:  Color { Color(red: 0.208, green: 0.816, blue: 0.498) }

    // ── CTA surfaces (used by primary actions like "New Tab") ────────────
    /// Soft sky blue (#ACDBE9) for light mode; a muted, lower-luminance variant for dark mode so it doesn't glow.
    var ctaBg: Color {
        isDark ? Color(red: 0.674, green: 0.859, blue: 0.914).opacity(0.22)
               : Color(red: 0.674, green: 0.859, blue: 0.914)
    }
    var ctaBgHover: Color {
        isDark ? Color(red: 0.674, green: 0.859, blue: 0.914).opacity(0.32)
               : Color(red: 0.612, green: 0.820, blue: 0.886)
    }
    var ctaFg: Color {
        isDark ? Color(red: 0.674, green: 0.859, blue: 0.914)
               : Color(red: 0.10, green: 0.30, blue: 0.40)
    }

    // ── Pill (rest-state edge indicator) ──────────────────────────────
    /// The pill stays "always-dark" by design — it's a thin edge marker that needs
    /// to read against any desktop wallpaper, light or dark. Use these tokens rather
    /// than inlining the raw values so a future redesign can re-skin from one place.
    var pillBg:     Color { Color.black.opacity(0.96) }
    var pillBorder: Color { Color.white.opacity(0.10) }

    // ── Status dots ───────────────────────────────────────────────────
    var dotIdle: Color { isDark ? Color(white: 1.0, opacity: 0.22) : Color(white: 0.0, opacity: 0.18) }
    var dotLive: Color { Color(red: 0.21,  green: 0.82,  blue: 0.50) }
    var dotAttn: Color { Color(red: 0.95,  green: 0.71,  blue: 0.18) }
    var dotDead: Color { Color(red: 0.973, green: 0.443, blue: 0.443, opacity: 0.60) }

    // ── Derived tints (replaces inline .opacity() on tokens in views) ────
    /// Soft accent fill for "Open as Tab" pills and similar tinted callouts.
    var accentTint:  Color { accent.opacity(0.12) }
    /// Hairline border on CTA buttons (sky-blue family).
    var ctaBorder:   Color { ctaFg.opacity(0.20) }
    /// Border colour for a focused text field (find bar etc.).
    var focusBorder: Color { accentReadable.opacity(0.55) }
    /// Settings/About card background — slightly lighter than panel L1 in light mode.
    var aboutBg:     Color { isDark ? Self.darkL3 : Color(white: 0.96) }
    /// Fully opaque header background for the Notes tab — matches nsNoteBg so scrolling content can't bleed through.
    var noteHeaderBg: Color { isDark ? Color(red: 0.082, green: 0.090, blue: 0.125) : Color(white: 0.941) }
}

// MARK: - AppKit tokens (for NSViewRepresentable — must be concrete opaque NSColors)
extension NookTheme {
    /// Opaque editor background for NotesEditorView (AppKit layer).
    var nsNoteBg: NSColor {
        isDark ? NSColor(red: 0.082, green: 0.090, blue: 0.125, alpha: 1.0) // #151720
               : NSColor(white: 0.941, alpha: 1.0)
    }
    /// Text color for Notes editor.
    var nsNoteFg: NSColor {
        isDark ? NSColor(red: 0.922, green: 0.933, blue: 0.961, alpha: 0.92)
               : NSColor(white: 0.078, alpha: 0.88)
    }
    /// Gutter background — distinctly themed so the line-number column is dark
    /// in dark mode and light in light mode (NSRulerView defaults to system
    /// control white, which is unreadable in dark mode).
    var nsNoteGutterBg: NSColor {
        isDark ? NSColor(red: 0.039, green: 0.047, blue: 0.078, alpha: 1.0)  // #0A0C14, deeper than editor #151720
               : NSColor(white: 0.84, alpha: 1.0)                             // grayer than #F0F0F0 editor
    }
    /// Theme-aware line-number color, with enough alpha to actually read
    /// against the gutter bg in both modes.
    var nsNoteGutterFg: NSColor {
        isDark ? NSColor(red: 0.784, green: 0.804, blue: 0.863, alpha: 0.70)
               : NSColor(white: 0.30, alpha: 0.75)
    }
    /// Hairline separator between gutter and text area.
    var nsNoteGutterSeparator: NSColor {
        isDark ? NSColor.white.withAlphaComponent(0.08)
               : NSColor.black.withAlphaComponent(0.08)
    }

    // ── Terminal AppKit colours (SwiftTerm requires opaque NSColor) ──────
    /// Opaque terminal background; matches `termBg` SwiftUI token.
    var nsTermBg: NSColor {
        isDark ? NSColor(red: 0.114, green: 0.118, blue: 0.141, alpha: 1.0)  // #1d1e24
               : NSColor(red: 0.961, green: 0.961, blue: 0.957, alpha: 1.0)
    }
    /// Default terminal foreground colour.
    var nsTermFg: NSColor {
        isDark ? NSColor(red: 0.910, green: 0.910, blue: 0.918, alpha: 1.0)
               : NSColor(red: 0.282, green: 0.282, blue: 0.298, alpha: 1.0)
    }
    /// Selection highlight in the terminal (sky-blue tint, not the global accent).
    var nsTermSelectionBg: NSColor {
        isDark ? NSColor(red: 0.55, green: 0.80, blue: 1.0, alpha: 0.38)
               : NSColor(red: 0.60, green: 0.84, blue: 1.0, alpha: 0.55)
    }
}

// MARK: - Typography tokens
/// Centralised font catalogue. Use these instead of inlining
/// `.font(.system(size:weight:design:))` in views so type ramps stay
/// consistent across screens.
enum NookType {
    // Body / row text (13pt)
    static let body       = Font.system(size: 13, weight: .medium)
    static let bodyEmph   = Font.system(size: 13, weight: .semibold)
    static let bodyReg    = Font.system(size: 13)
    static let bodyMono   = Font.system(size: 13, design: .monospaced)
    static let bodyMonoEmph = Font.system(size: 13, weight: .medium, design: .monospaced)

    // Labels (12pt)
    static let label      = Font.system(size: 12, weight: .medium)
    static let labelEmph  = Font.system(size: 12, weight: .semibold)
    static let labelReg   = Font.system(size: 12)
    static let labelMono  = Font.system(size: 12, weight: .medium, design: .monospaced)

    // Captions (11pt)
    static let caption      = Font.system(size: 11)
    static let captionEmph  = Font.system(size: 11, weight: .medium)
    static let captionStrong = Font.system(size: 11, weight: .semibold)
    static let captionBold  = Font.system(size: 11, weight: .bold)

    // Micro (10pt)
    static let micro      = Font.system(size: 10, weight: .medium)
    static let microMono  = Font.system(size: 10, design: .monospaced)
    static let microStrong = Font.system(size: 10, weight: .semibold)

    // Sub-micro
    static let chevron    = Font.system(size: 8,  weight: .medium)
    static let chevronStrong = Font.system(size: 8, weight: .semibold)
    static let pip        = Font.system(size: 8,  weight: .bold)
    static let closeGlyph = Font.system(size: 9,  weight: .bold)

    // Form values (14pt — settings field text, larger icons)
    static let formValue  = Font.system(size: 14)
    static let formValueEmph = Font.system(size: 14, weight: .medium)
    static let formValueStrong = Font.system(size: 14, weight: .semibold)

    // Hero (one-off large text in About / empty states)
    static let heroXL     = Font.system(size: 28, weight: .medium)
    static let heroL      = Font.system(size: 24, weight: .light)
    static let heroM      = Font.system(size: 20, weight: .bold)
}

// MARK: - Corner radius tokens
enum NookRadius {
    static let xs: CGFloat = 4   // tight pills, kbd chips, small inputs
    static let sm: CGFloat = 6   // medium chips, gutter rows
    static let md: CGFloat = 8   // standard buttons, tab cards
    static let lg: CGFloat = 10  // grouped surfaces, terminal clip
    static let xl: CGFloat = 14  // outermost panel shape
}

// MARK: - Color ↔ Hex utilities
extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    }

    func hexString() -> String? {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int((c.redComponent   * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent  * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
