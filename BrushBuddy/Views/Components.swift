import SwiftUI

/// Thin circular progress ring.
struct ProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 8
    var label: String = ""

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            if !label.isEmpty {
                Text(label)
                    .font(.display(20))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
    }
}

/// One thin segment per step.
struct StepSegmentBar: View {
    var steps: [StageStep]
    var currentIndex: Int
    var currentProgress: Double
    var color: Color

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, _ in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(color).frame(width: geo.size.width * fill(for: index))
                    }
                }
                .frame(height: 4)
            }
        }
    }

    private func fill(for index: Int) -> CGFloat {
        if index < currentIndex { return 1 }
        if index == currentIndex { return CGFloat(currentProgress) }
        return 0
    }
}

/// Rotating advice card. Tips appear in a random order (no repeats until all
/// have been shown), change slowly, and advance on tap.
struct TipCarousel: View {
    var tips: [Tip]
    var color: Color
    var interval: TimeInterval = 18

    @State private var order: [Tip] = []
    @State private var manualOffset = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { context in
            let deck = order.isEmpty ? tips : order
            let auto = Int(context.date.timeIntervalSinceReferenceDate / interval)
            let index = deck.isEmpty ? 0 : ((auto + manualOffset) % deck.count + deck.count) % deck.count
            if let tip = deck.indices.contains(index) ? deck[index] : nil {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tip.kind == .warning ? Theme.warn : color)
                        .frame(width: 26)
                        .padding(.top, 1)
                    Text(tip.text)
                        .font(.body)
                        .lineSpacing(3)
                        .foregroundStyle(Theme.text.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(padding: 18, radius: 22)
                .id(tip.id)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.6), value: index)
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.tap()
                    withAnimation { manualOffset += 1 }
                }
                .accessibilityHint("Tap for the next tip")
            }
        }
        .onAppear { if order.isEmpty { order = tips.shuffled() } }
    }
}

/// Round icon in a tinted disc.
struct IconDisc: View {
    var symbol: String
    var color: Color
    var size: CGFloat = 46
    var filled = false

    var body: some View {
        ZStack {
            Circle().fill(filled ? color : color.opacity(0.16))
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(filled ? Theme.bg : color)
        }
        .frame(width: size, height: size)
    }
}

/// Wide pill button.
struct PillButtonStyle: ButtonStyle {
    var color: Color
    var foreground: Color = Theme.bg
    var height: CGFloat = 58

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(18, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
            .foregroundStyle(foreground)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Subtle glass pill button.
struct GhostButtonStyle: ButtonStyle {
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Theme.surfaceRaised.opacity(configuration.isPressed ? 0.6 : 1), in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.stroke))
            .foregroundStyle(Theme.text)
    }
}

/// Round control button.
struct RoundButtonStyle: ButtonStyle {
    var color: Color
    var size: CGFloat = 72
    var filled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.36, weight: .bold))
            .frame(width: size, height: size)
            .background(filled ? color : Theme.surfaceRaised, in: Circle())
            .overlay(Circle().strokeBorder(filled ? .clear : Theme.stroke))
            .foregroundStyle(filled ? Theme.bg : Theme.text)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// The tooth that fronts the app. Refined: a clean glowing silhouette.
/// Kids: the same tooth with a cheerful face.
struct ToothMascot: View {
    var size: CGFloat = 120
    var mood: Mood = .happy
    @Environment(\.visualStyle) private var style

    enum Mood { case happy, sleepy, cheering }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let kids = style == .kids
            let bob = sin(t * (kids ? 2.2 : 1.6)) * size * (kids ? 0.03 : 0.015)
            let squash = kids ? 1 + sin(t * 2.2) * 0.02 : 1
            ZStack {
                ToothShape()
                    .fill(LinearGradient(colors: [.white, Color(red: 0.78, green: 0.86, blue: 0.97)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: (kids ? Theme.kidsPink : Theme.accent).opacity(mood == .cheering ? 0.6 : 0.35), radius: size * 0.2, y: size * 0.05)
                if kids {
                    ToothShape().stroke(Color(red: 0.55, green: 0.66, blue: 0.78), lineWidth: size * 0.025)
                    face
                } else {
                    ToothShape()
                        .fill(LinearGradient(colors: [.white.opacity(0.7), .clear], startPoint: .top, endPoint: .center))
                        .padding(size * 0.08)
                        .blendMode(.plusLighter)
                }
            }
            .frame(width: size, height: size * 1.1)
            .scaleEffect(x: 1 / squash, y: squash)
            .offset(y: bob)
        }
        .accessibilityHidden(true)
    }

    private var face: some View {
        VStack(spacing: size * 0.06) {
            HStack(spacing: size * 0.18) { eye; eye }
                .padding(.top, size * 0.28)
            Group {
                switch mood {
                case .cheering:
                    Ellipse().fill(Color(red: 0.45, green: 0.15, blue: 0.25)).frame(width: size * 0.22, height: size * 0.16)
                        .overlay(alignment: .bottom) { Capsule().fill(Color(red: 0.96, green: 0.55, blue: 0.62)).frame(width: size * 0.12, height: size * 0.07).offset(y: -size * 0.01) }
                default:
                    SmileShape()
                        .stroke(Color(red: 0.45, green: 0.15, blue: 0.25), style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                        .frame(width: size * 0.3, height: size * 0.12)
                }
            }
            Spacer()
        }
        .overlay {
            HStack(spacing: size * 0.44) {
                Circle().fill(Theme.kidsPink.opacity(0.45)).frame(width: size * 0.12)
                Circle().fill(Theme.kidsPink.opacity(0.45)).frame(width: size * 0.12)
            }
            .offset(y: -size * 0.02)
        }
    }

    private var eye: some View {
        ZStack {
            Circle().fill(Color(red: 0.2, green: 0.2, blue: 0.3)).frame(width: size * 0.10, height: mood == .sleepy ? size * 0.03 : size * 0.10)
            Circle().fill(.white).frame(width: size * 0.035).offset(x: size * 0.02, y: -size * 0.02).opacity(mood == .sleepy ? 0 : 1)
        }
    }
}

/// A cartoon molar: broad crown with two gentle bumps and two roots.
struct ToothShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.10, y: h * 0.30))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.16), control1: CGPoint(x: w * 0.10, y: -h * 0.02), control2: CGPoint(x: w * 0.42, y: -h * 0.02))
        p.addCurve(to: CGPoint(x: w * 0.90, y: h * 0.30), control1: CGPoint(x: w * 0.58, y: -h * 0.02), control2: CGPoint(x: w * 0.90, y: -h * 0.02))
        p.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.96), control1: CGPoint(x: w * 0.98, y: h * 0.60), control2: CGPoint(x: w * 0.92, y: h * 0.96))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.62), control1: CGPoint(x: w * 0.66, y: h * 0.96), control2: CGPoint(x: w * 0.60, y: h * 0.62))
        p.addCurve(to: CGPoint(x: w * 0.20, y: h * 0.96), control1: CGPoint(x: w * 0.40, y: h * 0.62), control2: CGPoint(x: w * 0.34, y: h * 0.96))
        p.addCurve(to: CGPoint(x: w * 0.10, y: h * 0.30), control1: CGPoint(x: w * 0.08, y: h * 0.96), control2: CGPoint(x: w * 0.02, y: h * 0.60))
        p.closeSubpath()
        return p
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return p
    }
}
