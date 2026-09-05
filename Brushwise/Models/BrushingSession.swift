import Foundation

/// Morning or night. Best practice is to brush twice a day, so we track both.
enum DaySlot: String, Codable, CaseIterable, Identifiable {
    case morning
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .night: return "Night"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        }
    }

    /// The day boundary sits at 4 am, so a late-night brush at 1 am still
    /// counts as the previous day's night routine.
    static let dayBoundaryHour = 4

    /// Everything from 4 am up to 4 pm is "morning"; the rest is "night".
    static func slot(for date: Date, calendar: Calendar = .current) -> DaySlot {
        let hour = calendar.component(.hour, from: date)
        return (hour >= dayBoundaryHour && hour < 16) ? .morning : .night
    }

    /// Start of the logical day a date belongs to (shifted by the 4 am boundary).
    static func dayKey(for date: Date, calendar: Calendar = .current) -> Date {
        let shifted = date.addingTimeInterval(-TimeInterval(dayBoundaryHour * 3600))
        return calendar.startOfDay(for: shifted)
    }
}

enum SessionStatus: Equatable {
    case none
    case partial(done: Int, planned: Int)
    case complete
}

/// One run through the routine.
struct BrushingSession: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var startedAt: Date
    var endedAt: Date
    var slot: DaySlot
    var plannedStages: [BrushingStage]
    var completedStages: [BrushingStage]
    /// When the brushing stage itself ran, for logging to Apple Health.
    var brushingStart: Date? = nil
    var brushingEnd: Date? = nil

    var brushingInterval: DateInterval? {
        guard let brushingStart, let brushingEnd, brushingEnd > brushingStart else { return nil }
        return DateInterval(start: brushingStart, end: brushingEnd)
    }

    var isComplete: Bool {
        !plannedStages.isEmpty && Set(plannedStages).isSubset(of: Set(completedStages))
    }

    var status: SessionStatus {
        if isComplete { return .complete }
        let done = Set(plannedStages).intersection(completedStages).count
        if done == 0 { return .none }
        return .partial(done: done, planned: plannedStages.count)
    }

    var dayKey: Date { DaySlot.dayKey(for: startedAt) }
}
