import SwiftUI

/// Last seven days as two rows of dots: morning and night.
struct WeekHistoryView: View {
    @Environment(BrushStore.self) private var store
    var now: Date

    private var days: [Date] { store.lastSevenDays(now: now) }
    private var today: Date { store.today(now: now) }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This week")
                    .font(.display(17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                let streak = store.currentStreak(now: now)
                if streak > 0 {
                    Label("\(streak)-day streak", systemImage: "flame.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.warn)
                } else {
                    Text("\(store.completedRoutinesThisWeek(now: now)) of 14")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            HStack(spacing: 0) {
                VStack(spacing: 10) {
                    Color.clear.frame(height: 14)
                    Image(systemName: DaySlot.morning.symbol).font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.textTertiary).frame(height: 16)
                    Image(systemName: DaySlot.night.symbol).font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.textTertiary).frame(height: 16)
                }
                .frame(width: 22)
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 10) {
                        Text(day, format: .dateTime.weekday(.narrow))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(day == today ? Theme.accent : Theme.textTertiary)
                            .frame(height: 14)
                        dot(day: day, slot: .morning)
                        dot(day: day, slot: .night)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glass(padding: 20)
    }

    @ViewBuilder
    private func dot(day: Date, slot: DaySlot) -> some View {
        let status = store.status(onDayKey: day, slot: slot)
        let upcoming = day == today && status == .none
            && (slot == .night ? DaySlot.slot(for: now) == .morning : false)
        ZStack {
            switch status {
            case .complete:
                Circle().fill(Theme.good)
            case .partial(let done, let planned):
                Circle().fill(Theme.warn.opacity(0.18))
                Circle()
                    .trim(from: 0, to: CGFloat(done) / CGFloat(max(1, planned)))
                    .stroke(Theme.warn, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(1.5)
            case .none:
                Circle().fill(Color.white.opacity(upcoming ? 0.05 : 0.10))
                if upcoming {
                    Circle().stroke(Theme.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
                }
            }
        }
        .frame(width: 16, height: 16)
        .accessibilityLabel("\(slot.title) \(day.formatted(.dateTime.weekday(.wide))): \(accessibilityText(status))")
    }

    private func accessibilityText(_ status: SessionStatus) -> String {
        switch status {
        case .complete: return "complete"
        case .partial(let d, let p): return "\(d) of \(p) stages"
        case .none: return "not done"
        }
    }
}
