import Foundation

struct AppSettings: Codable, Equatable {
    /// Stages the user has switched on for each part of the day.
    var morningStages: Set<BrushingStage> = Set(BrushingStage.allCases)
    var nightStages: Set<BrushingStage> = Set(BrushingStage.allCases)

    var remindersEnabled: Bool = true
    /// Minutes after midnight. Defaults: 08:00 and 20:00.
    var morningReminderMinutes: Int = 8 * 60
    var nightReminderMinutes: Int = 20 * 60

    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true

    /// Playful cartoon graphics (the default look). Off gives the refined diagram style.
    var kidsMode: Bool = true

    /// Write each completed brushing to Apple Health as a Tooth Brushing event.
    var healthSyncEnabled: Bool = false

    /// When the user last put a new brush (or brush head) into service.
    var brushReplacedOn: Date? = nil
    /// When the end-of-routine bristle check was last shown. It appears once a week.
    var lastBrushCheckOn: Date? = nil

    static let brushCheckIntervalDays = 7

    init() {}

    // Tolerant decoding: keys added in later versions fall back to their
    // defaults instead of failing (which would silently reset every setting).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        morningStages = try c.decodeIfPresent(Set<BrushingStage>.self, forKey: .morningStages) ?? morningStages
        nightStages = try c.decodeIfPresent(Set<BrushingStage>.self, forKey: .nightStages) ?? nightStages
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? remindersEnabled
        morningReminderMinutes = try c.decodeIfPresent(Int.self, forKey: .morningReminderMinutes) ?? morningReminderMinutes
        nightReminderMinutes = try c.decodeIfPresent(Int.self, forKey: .nightReminderMinutes) ?? nightReminderMinutes
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? soundEnabled
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? hapticsEnabled
        kidsMode = try c.decodeIfPresent(Bool.self, forKey: .kidsMode) ?? kidsMode
        healthSyncEnabled = try c.decodeIfPresent(Bool.self, forKey: .healthSyncEnabled) ?? healthSyncEnabled
        brushReplacedOn = try c.decodeIfPresent(Date.self, forKey: .brushReplacedOn)
        lastBrushCheckOn = try c.decodeIfPresent(Date.self, forKey: .lastBrushCheckOn)
    }

    /// Conservative end of the 3–4 months recommended by the ADA ([ADA-care] in DentalAdvice.swift).
    static let brushLifetimeDays = 90

    func isEnabled(_ stage: BrushingStage, in slot: DaySlot) -> Bool {
        stages(for: slot).contains(stage)
    }

    func stages(for slot: DaySlot) -> Set<BrushingStage> {
        switch slot {
        case .morning: return morningStages
        case .night: return nightStages
        }
    }

    /// Enabled stages in the recommended order.
    func orderedStages(for slot: DaySlot) -> [BrushingStage] {
        BrushingStage.recommendedOrder.filter { stages(for: slot).contains($0) }
    }

    func disabledStages(for slot: DaySlot) -> [BrushingStage] {
        BrushingStage.recommendedOrder.filter { !stages(for: slot).contains($0) }
    }

    mutating func setEnabled(_ enabled: Bool, stage: BrushingStage, in slot: DaySlot) {
        switch slot {
        case .morning:
            if enabled { morningStages.insert(stage) } else { morningStages.remove(stage) }
        case .night:
            if enabled { nightStages.insert(stage) } else { nightStages.remove(stage) }
        }
    }

    func reminderMinutes(for slot: DaySlot) -> Int {
        switch slot {
        case .morning: return morningReminderMinutes
        case .night: return nightReminderMinutes
        }
    }

    mutating func setReminderMinutes(_ minutes: Int, for slot: DaySlot) {
        switch slot {
        case .morning: morningReminderMinutes = minutes
        case .night: nightReminderMinutes = minutes
        }
    }

    /// Days since the brush was replaced, or nil if we don't know.
    func brushAgeDays(asOf now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let replaced = brushReplacedOn else { return nil }
        let start = calendar.startOfDay(for: replaced)
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: start, to: today).day
    }

    /// True when it has been a week or more since the last bristle check.
    func isBrushCheckDue(asOf now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let last = lastBrushCheckOn else { return true }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: now)).day ?? 0
        return days >= AppSettings.brushCheckIntervalDays
    }

    func brushNeedsReplacing(asOf now: Date = Date()) -> Bool {
        guard let age = brushAgeDays(asOf: now) else { return false }
        return age >= AppSettings.brushLifetimeDays
    }
}
