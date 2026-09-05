import SwiftUI

@main
struct BrushwiseApp: App {
    @State private var store = BrushwiseApp.makeStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
                .task {
                    SoundPlayer.shared.isEnabled = store.settings.soundEnabled
                    Haptics.isEnabled = store.settings.hapticsEnabled
                    // Re-schedule reminders if allowed, but never prompt on launch.
                    await NotificationManager.shared.sync(with: store.settings, promptIfNeeded: false)
                }
        }
    }

    @MainActor
    private static func makeStore() -> BrushStore {
        #if DEBUG
        if DemoOptions.current.seedHistory {
            return BrushStore.inMemory(settings: DemoOptions.sampleSettings, sessions: DemoOptions.sampleSessions())
        }
        #endif
        return BrushStore()
    }
}

#if DEBUG
/// Launch arguments for previews and screenshots, e.g.
/// `xcrun simctl launch <udid> com.alexcollins.brushwise -demoScreen routine -demoStage brush`.
/// Values arrive through the UserDefaults argument domain.
struct DemoOptions {
    /// "routine" or "settings".
    let screen: String?
    /// Start the routine from this stage onward.
    let stage: BrushingStage?
    /// "stageComplete", "brushCheck" or "finished".
    let phase: String?
    let seedHistory: Bool
    let skipNotifications: Bool

    static let current: DemoOptions = {
        let d = UserDefaults.standard
        return DemoOptions(
            screen: d.string(forKey: "demoScreen"),
            stage: d.string(forKey: "demoStage").flatMap(BrushingStage.init(rawValue:)),
            phase: d.string(forKey: "demoPhase"),
            seedHistory: d.bool(forKey: "demoHistory"),
            skipNotifications: d.bool(forKey: "skipNotifications")
        )
    }()

    static var sampleSettings: AppSettings {
        var s = AppSettings()
        s.brushReplacedOn = Calendar.current.date(byAdding: .day, value: -95, to: Date())
        return s
    }

    static func sampleSessions() -> [BrushingSession] {
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        var out: [BrushingSession] = []
        let all = BrushingStage.allCases
        for daysAgo in 1...6 {
            let day = cal.date(byAdding: .day, value: -daysAgo, to: noon)!
            let morningDone: [BrushingStage] = daysAgo == 4 ? [.floss, .brush] : all
            out.append(BrushingSession(startedAt: day, endedAt: day.addingTimeInterval(330), slot: .morning, plannedStages: all, completedStages: morningDone))
            if daysAgo != 5 {
                let night = day.addingTimeInterval(12 * 3600)
                out.append(BrushingSession(startedAt: night, endedAt: night.addingTimeInterval(330), slot: .night, plannedStages: all, completedStages: all))
            }
        }
        out.append(BrushingSession(startedAt: noon, endedAt: noon.addingTimeInterval(330), slot: .morning, plannedStages: all, completedStages: all))
        return out
    }
}
#endif
