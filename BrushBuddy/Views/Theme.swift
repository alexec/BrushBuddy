import SwiftUI

/// Dark, glassy palette. Stage colours are brightened to read well on it.
enum Theme {
    static let bg = Color(red: 0.05, green: 0.07, blue: 0.13)
    static let bg2 = Color(red: 0.08, green: 0.12, blue: 0.21)
    static let surface = Color.white.opacity(0.07)
    static let surfaceRaised = Color.white.opacity(0.11)
    static let stroke = Color.white.opacity(0.09)
    static let text = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    static let accent = Color(red: 0.38, green: 0.80, blue: 1.0)
    static let good = Color(red: 0.36, green: 0.87, blue: 0.63)
    static let warn = Color(red: 1.0, green: 0.73, blue: 0.36)

    static let water = Color(red: 0.45, green: 0.78, blue: 1.0)
    static let kidsPink = Color(red: 1.0, green: 0.55, blue: 0.75)

    /// Page background with a soft glow of `tint` at the top. Kids mode adds a
    /// second, warmer glow so the page feels more playful.
    static func background(tint: Color, style: VisualStyle = .refined) -> some View {
        ZStack {
            LinearGradient(colors: [bg2, bg], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [tint.opacity(style == .kids ? 0.5 : 0.38), .clear], center: UnitPoint(x: 0.5, y: 0.0), startRadius: 0, endRadius: 520)
            RadialGradient(colors: [(style == .kids ? kidsPink : tint).opacity(style == .kids ? 0.3 : 0.16), .clear], center: UnitPoint(x: 0.9, y: 0.9), startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

/// Refined: clean diagram-style drawings. Kids: cartoon faces, lips, fingers,
/// vivid colours and rainbow confetti.
enum VisualStyle {
    case refined
    case kids
}

private struct VisualStyleKey: EnvironmentKey {
    static let defaultValue: VisualStyle = .refined
}

extension EnvironmentValues {
    var visualStyle: VisualStyle {
        get { self[VisualStyleKey.self] }
        set { self[VisualStyleKey.self] = newValue }
    }
}

/// Colours and flags used by the Canvas drawings, per visual style.
struct DrawPalette {
    let gum: Color
    let gumDark: Color
    let tooth: Color
    let toothDim: Color
    let mouthInterior: Color
    let tongue: Color
    let skin: Color
    /// Draw lips, tooth outlines, molar fissures and the tongue midline.
    let detailed: Bool

    static func forStyle(_ style: VisualStyle) -> DrawPalette {
        switch style {
        case .refined:
            return DrawPalette(
                gum: Color(red: 0.85, green: 0.50, blue: 0.60).opacity(0.45),
                gumDark: Color(red: 0.85, green: 0.50, blue: 0.60).opacity(0.7),
                tooth: .white,
                toothDim: Color.white.opacity(0.22),
                mouthInterior: Color.black.opacity(0.28),
                tongue: Color(red: 0.85, green: 0.50, blue: 0.60).opacity(0.35),
                skin: Color.white.opacity(0.9),
                detailed: false)
        case .kids:
            return DrawPalette(
                gum: Color(red: 0.98, green: 0.62, blue: 0.68),
                gumDark: Color(red: 0.86, green: 0.45, blue: 0.54),
                tooth: .white,
                toothDim: Color(red: 0.78, green: 0.80, blue: 0.86),
                mouthInterior: Color(red: 0.30, green: 0.12, blue: 0.20),
                tongue: Color(red: 0.96, green: 0.55, blue: 0.62),
                skin: Color(red: 0.99, green: 0.85, blue: 0.72),
                detailed: true)
        }
    }
}

struct GlassCard: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = 26
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

extension View {
    func glass(padding: CGFloat = 18, radius: CGFloat = 26) -> some View { modifier(GlassCard(padding: padding, radius: radius)) }
}

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension TimeInterval {
    /// "2:15" for durations, or "30s" for under a minute.
    var shortClock: String {
        let total = Int(self.rounded())
        if total < 60 { return "\(total)s" }
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var minutesRounded: String {
        let mins = (self / 60).rounded(.up)
        return mins <= 1 ? "1 min" : "\(Int(mins)) min"
    }
}
