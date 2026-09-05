import Foundation
import Observation

/// Owns settings and brushing history, and persists both.
@Observable
@MainActor
final class BrushStore {
    var settings: AppSettings {
        didSet { if settings != oldValue { saveSettings() } }
    }
    private(set) var sessions: [BrushingSession]

    private let defaults: UserDefaults
    private let sessionsURL: URL?
    private let calendar: Calendar

    private static let settingsKey = "brushwise.settings.v1"

    init(defaults: UserDefaults = .standard, sessionsURL: URL? = BrushStore.defaultSessionsURL(), calendar: Calendar = .current) {
        self.defaults = defaults
        self.sessionsURL = sessionsURL
        self.calendar = calendar

        if let data = defaults.data(forKey: BrushStore.settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
        }

        if let url = sessionsURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([BrushingSession].self, from: data) {
            sessions = decoded
        } else {
            sessions = []
        }
    }

    /// An in-memory store for previews and tests.
    static func inMemory(settings: AppSettings = AppSettings(), sessions: [BrushingSession] = []) -> BrushStore {
        let suite = UserDefaults(suiteName: "brushwise.preview.\(UUID().uuidString)")!
        let store = BrushStore(defaults: suite, sessionsURL: nil)
        store.settings = settings
        store.sessions = sessions
        return store
    }

    nonisolated static func defaultSessionsURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = dir.appendingPathComponent("Brushwise", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("sessions.json")
    }

    // MARK: - Recording

    func record(_ session: BrushingSession) {
        sessions.append(session)
        sessions.sort { $0.startedAt < $1.startedAt }
        saveSessions()
    }

    // MARK: - Queries

    /// Sessions on the logical day containing `date`.
    func sessions(on date: Date, slot: DaySlot) -> [BrushingSession] {
        sessions(onDayKey: DaySlot.dayKey(for: date, calendar: calendar), slot: slot)
    }

    /// Sessions for an already-normalised day key (see `DaySlot.dayKey`).
    /// Day keys must not be normalised again: doing so shifts them back a day.
    func sessions(onDayKey key: Date, slot: DaySlot) -> [BrushingSession] {
        sessions.filter { $0.slot == slot && DaySlot.dayKey(for: $0.startedAt, calendar: calendar) == key }
    }

    /// The best result for a slot on the logical day containing `date`.
    func status(on date: Date, slot: DaySlot) -> SessionStatus {
        status(onDayKey: DaySlot.dayKey(for: date, calendar: calendar), slot: slot)
    }

    /// The best result for a slot on a day key: complete beats partial beats nothing.
    func status(onDayKey key: Date, slot: DaySlot) -> SessionStatus {
        let matches = sessions(onDayKey: key, slot: slot)
        if matches.contains(where: { $0.isComplete }) { return .complete }
        var best: SessionStatus = .none
        for s in matches {
            if case .partial(let done, let planned) = s.status {
                if case .partial(let bestDone, _) = best, bestDone >= done { continue }
                best = .partial(done: done, planned: planned)
            }
        }
        return best
    }

    /// Logical "today", honouring the 4 am boundary.
    func today(now: Date = Date()) -> Date {
        DaySlot.dayKey(for: now, calendar: calendar)
    }

    /// The last seven logical day keys, oldest first, ending today.
    func lastSevenDays(now: Date = Date()) -> [Date] {
        let today = today(now: now)
        return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    /// Consecutive days, ending today or yesterday, with both a complete
    /// morning and a complete night routine.
    func currentStreak(now: Date = Date()) -> Int {
        var day = today(now: now)
        var streak = 0
        let bothDone: (Date) -> Bool = { key in
            self.status(onDayKey: key, slot: .morning) == .complete && self.status(onDayKey: key, slot: .night) == .complete
        }
        // Today may still be in progress, so it counts only if already done.
        if bothDone(day) {
            streak += 1
        }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return streak }
        day = yesterday
        while bothDone(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// Number of complete routines (morning + night) in the last seven days.
    func completedRoutinesThisWeek(now: Date = Date()) -> Int {
        lastSevenDays(now: now).reduce(0) { total, key in
            total + DaySlot.allCases.filter { status(onDayKey: key, slot: $0) == .complete }.count
        }
    }

    // MARK: - Persistence

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: BrushStore.settingsKey)
        }
    }

    private func saveSessions() {
        guard let url = sessionsURL else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(sessions) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
