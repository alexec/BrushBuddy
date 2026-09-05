import SwiftUI

struct RoutineCompleteView: View {
    @Environment(BrushStore.self) private var store
    @Environment(\.visualStyle) private var style
    var session: BrushingSession
    var onClose: () -> Void

    var body: some View {
        ZStack {
            ConfettiBurst(color: Theme.accent, count: 28)
            VStack(spacing: 18) {
                Spacer()
                if style == .kids {
                    ToothMascot(size: 130, mood: .cheering)
                } else {
                ZStack {
                    Circle().stroke(Theme.accent.opacity(0.25), lineWidth: 10).frame(width: 132, height: 132)
                    Circle().trim(from: 0, to: session.isComplete ? 1 : CGFloat(session.completedStages.count) / CGFloat(max(1, session.plannedStages.count)))
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 132, height: 132)
                    Image(systemName: "checkmark")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Theme.text)
                }
                .shadow(color: Theme.accent.opacity(0.4), radius: 24)
                }
                Text(session.isComplete ? "All done!" : "Nice work!")
                    .font(.display(38))
                    .foregroundStyle(Theme.text)
                Text(session.isComplete
                     ? "\(session.slot.title) routine complete."
                     : "\(session.completedStages.count) of \(session.plannedStages.count) stages finished.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 14) {
                    ForEach(session.plannedStages) { stage in
                        let done = session.completedStages.contains(stage)
                        IconDisc(symbol: done ? "checkmark" : stage.symbol, color: done ? stage.color : Theme.textTertiary, size: 46, filled: done)
                    }
                }
                .padding(.top, 4)

                let streak = store.currentStreak()
                if streak > 0 {
                    Label("\(streak)-day streak", systemImage: "flame.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.warn)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Theme.warn.opacity(0.14), in: Capsule())
                }

                Spacer()

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "clock.fill").foregroundStyle(Theme.accent).padding(.top, 1)
                    // [NHS-clean]: spit don't rinse after brushing; no food or drink for 30 minutes after fluoride mouthwash.
                    Text("For the next 30 minutes, don't eat, drink or rinse — let the fluoride keep working.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(padding: 14, radius: 18)
                .padding(.horizontal, 20)

                Button {
                    Haptics.tap()
                    onClose()
                } label: {
                    Text("Done")
                }
                .buttonStyle(PillButtonStyle(color: Theme.accent))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}
