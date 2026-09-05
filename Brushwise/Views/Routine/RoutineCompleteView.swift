import SwiftUI

struct RoutineCompleteView: View {
    @Environment(BrushStore.self) private var store
    var session: BrushingSession
    var onClose: () -> Void

    var body: some View {
        ZStack {
            ConfettiBurst(color: Theme.accent)
            VStack(spacing: 18) {
                Spacer()
                ToothMascot(size: 130, mood: .cheering)
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
