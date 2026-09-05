import SwiftUI

/// Celebration shown when a stage finishes. Auto-advances after a few seconds
/// or on tap, so wet hands aren't a problem.
struct StageCompleteOverlay: View {
    var engine: RoutineEngine
    @State private var appeared = false

    var body: some View {
        let stage = engine.completedStages.last ?? engine.currentStage ?? .brush
        ZStack {
            LinearGradient(colors: [stage.color, stage.color.opacity(0.75), Theme.bg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ConfettiBurst(color: .white)
            VStack(spacing: 16) {
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 168, height: 168)
                    Circle().fill(.white).frame(width: 120, height: 120)
                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(stage.color)
                }
                .scaleEffect(appeared ? 1 : 0.4)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                Text(stage.completionCheer)
                    .font(.display(34))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 6) {
                    Text("UP NEXT").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(.white.opacity(0.7))
                    if let next = engine.nextStage {
                        Label(next.title, systemImage: next.symbol)
                            .font(.display(22, weight: .semibold))
                            .foregroundStyle(.white)
                    } else {
                        Label("Toothbrush check", systemImage: "checkmark.seal.fill")
                            .font(.display(22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Button {
                    Haptics.tap()
                    engine.continueAfterStageComplete()
                } label: {
                    HStack(spacing: 10) {
                        Text("Continue")
                        ProgressRing(progress: 1 - engine.autoAdvanceRemaining / RoutineEngine.autoAdvanceDelay, color: stage.color, lineWidth: 3)
                            .frame(width: 18, height: 18)
                    }
                }
                .buttonStyle(PillButtonStyle(color: .white, foreground: stage.color))
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { engine.continueAfterStageComplete() }
        .onAppear { appeared = true }
    }
}

/// Lightweight procedural confetti.
struct ConfettiBurst: View {
    var color: Color
    var count = 28
    @Environment(\.visualStyle) private var style

    var body: some View {
        let kids = style == .kids
        let pieces = kids ? count * 2 : count
        return TimelineView(.animation(minimumInterval: 1 / 40)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for i in 0..<pieces {
                    let seed = Draw.hash(i * 97 + 11)
                    let seed2 = Draw.hash(i * 31 + 5)
                    let speed = 0.25 + Double(seed2) * 0.35
                    let life = CGFloat((t * speed + Double(seed)).truncatingRemainder(dividingBy: 1))
                    let x = size.width * seed + sin(CGFloat(t) * 2 + seed * 10) * 20
                    let y = -20 + (size.height + 40) * life
                    let w: CGFloat = 6 + seed2 * 6
                    var piece = ctx
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .radians(CGFloat(t) * 3 * (seed > 0.5 ? 1 : -1) + seed * 6))
                    let fill: Color = kids ? Color(hue: Double(seed2), saturation: 0.6, brightness: 1).opacity(0.9) : color.opacity(0.35 + 0.35 * Double(seed2))
                    piece.fill(Path(roundedRect: CGRect(x: -w / 2, y: -w / 4, width: w, height: w / 2), cornerRadius: 1.5), with: .color(fill))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
