import XCTest
@testable import BrushBuddy

final class DaySlotTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testMorningAndNightSplit() {
        XCTAssertEqual(DaySlot.slot(for: date(2026, 9, 4, 7), calendar: calendar), .morning)
        XCTAssertEqual(DaySlot.slot(for: date(2026, 9, 4, 15, 59), calendar: calendar), .morning)
        XCTAssertEqual(DaySlot.slot(for: date(2026, 9, 4, 16), calendar: calendar), .night)
        XCTAssertEqual(DaySlot.slot(for: date(2026, 9, 4, 23), calendar: calendar), .night)
        XCTAssertEqual(DaySlot.slot(for: date(2026, 9, 5, 1), calendar: calendar), .night)
    }

    func testLateNightBelongsToPreviousDay() {
        let oneAM = date(2026, 9, 5, 1)
        let previousEvening = date(2026, 9, 4, 22)
        XCTAssertEqual(DaySlot.dayKey(for: oneAM, calendar: calendar), DaySlot.dayKey(for: previousEvening, calendar: calendar))
        XCTAssertNotEqual(DaySlot.dayKey(for: date(2026, 9, 5, 5), calendar: calendar), DaySlot.dayKey(for: previousEvening, calendar: calendar))
    }
}

@MainActor
final class BrushStoreTests: XCTestCase {
    private func session(_ start: Date, slot: DaySlot, planned: [BrushingStage] = BrushingStage.allCases, done: [BrushingStage]) -> BrushingSession {
        BrushingSession(startedAt: start, endedAt: start.addingTimeInterval(300), slot: slot, plannedStages: planned, completedStages: done)
    }

    func testStatusPrefersCompleteOverPartial() {
        let store = BrushStore.inMemory()
        let now = Date()
        store.record(session(now, slot: .morning, done: [.floss]))
        XCTAssertEqual(store.status(on: now, slot: .morning), .partial(done: 1, planned: 4))
        store.record(session(now.addingTimeInterval(60), slot: .morning, done: BrushingStage.allCases))
        XCTAssertEqual(store.status(on: now, slot: .morning), .complete)
        XCTAssertEqual(store.status(on: now, slot: .night), .none)
    }

    func testStreakCountsDaysWithBothSlotsComplete() {
        let store = BrushStore.inMemory()
        let cal = Calendar.current
        let now = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        for daysAgo in 1...3 {
            let day = cal.date(byAdding: .day, value: -daysAgo, to: now)!
            store.record(session(day, slot: .morning, done: BrushingStage.allCases))
            store.record(session(day.addingTimeInterval(9 * 3600), slot: .night, done: BrushingStage.allCases))
        }
        // Today is incomplete, so it doesn't break or extend the streak.
        XCTAssertEqual(store.currentStreak(now: now), 3)
        store.record(session(now, slot: .morning, done: BrushingStage.allCases))
        XCTAssertEqual(store.currentStreak(now: now), 3)
        store.record(session(now.addingTimeInterval(8 * 3600), slot: .night, done: BrushingStage.allCases))
        XCTAssertEqual(store.currentStreak(now: now), 4)
    }

    func testLastSevenDaysEndsToday() {
        let store = BrushStore.inMemory()
        let days = store.lastSevenDays()
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.last, store.today())
    }

    func testDayKeyStatusMatchesDateStatus() {
        let store = BrushStore.inMemory()
        let now = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
        store.record(session(now, slot: .night, done: BrushingStage.allCases))
        XCTAssertEqual(store.status(on: now, slot: .night), .complete)
        XCTAssertEqual(store.status(onDayKey: store.today(now: now), slot: .night), .complete)
        XCTAssertEqual(store.lastSevenDays(now: now).filter { store.status(onDayKey: $0, slot: .night) == .complete }.count, 1)
    }

    func testSettingsRoundTrip() throws {
        var settings = AppSettings()
        settings.setEnabled(false, stage: .waterPick, in: .morning)
        settings.morningReminderMinutes = 7 * 60 + 30
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(decoded, settings)
        XCTAssertEqual(decoded.orderedStages(for: .morning), [.floss, .brush, .mouthwash])
        XCTAssertEqual(decoded.orderedStages(for: .night), BrushingStage.allCases)
    }
}

@MainActor
final class RoutineEngineTests: XCTestCase {
    /// A controllable clock.
    final class Clock {
        var now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        func advance(_ s: TimeInterval) { now = now.addingTimeInterval(s) }
    }

    private func makeEngine(_ stages: [BrushingStage], clock: Clock) -> RoutineEngine {
        RoutineEngine(stages: stages, slot: .morning, now: { clock.now })
    }

    func testStepsAdvanceAndStageCompletes() {
        let clock = Clock()
        let engine = makeEngine([.mouthwash, .brush], clock: clock)
        var completedStages: [BrushingStage] = []
        var completedSteps = 0
        engine.onStageComplete = { completedStages.append($0) }
        engine.onStepComplete = { _ in completedSteps += 1 }
        engine.start()
        defer { engine.stop() }

        XCTAssertEqual(engine.currentStage, .mouthwash)
        clock.advance(10)
        engine.debugTick()
        XCTAssertEqual(engine.elapsedInStep, 10, accuracy: 0.01)
        XCTAssertEqual(engine.stepRemaining, 20, accuracy: 0.01)

        clock.advance(25) // past the 30 s swish
        engine.debugTick()
        XCTAssertEqual(engine.phase, .stageComplete)
        XCTAssertEqual(completedStages, [.mouthwash])
        XCTAssertEqual(completedSteps, 1)

        // Auto-advance after the celebration delay.
        clock.advance(RoutineEngine.autoAdvanceDelay + 0.1)
        engine.debugTick()
        XCTAssertEqual(engine.phase, .stage)
        XCTAssertEqual(engine.currentStage, .brush)
        XCTAssertEqual(engine.stepIndex, 0)
    }

    func testBackgroundCatchUpSpansMultipleSteps() {
        let clock = Clock()
        let engine = makeEngine([.brush], clock: clock)
        var steps: [String] = []
        engine.onStepComplete = { steps.append($0.id) }
        engine.start()
        defer { engine.stop() }

        clock.advance(65) // two 30 s quadrants plus 5 s into the third
        engine.debugTick()
        XCTAssertEqual(engine.stepIndex, 2)
        XCTAssertEqual(engine.elapsedInStep, 5, accuracy: 0.01)
        XCTAssertEqual(steps, ["br-ur", "br-ul"])
    }

    func testPauseFreezesTheClock() {
        let clock = Clock()
        let engine = makeEngine([.brush], clock: clock)
        engine.start()
        defer { engine.stop() }

        clock.advance(5)
        engine.debugTick()
        engine.pause()
        clock.advance(100)
        engine.debugTick()
        XCTAssertEqual(engine.elapsedInStep, 5, accuracy: 0.01)
        engine.resume()
        clock.advance(3)
        engine.debugTick()
        XCTAssertEqual(engine.elapsedInStep, 8, accuracy: 0.01)
        XCTAssertEqual(engine.stepIndex, 0)
    }

    func testUntimedStageCountsUpAndNextGoesStraightOn() {
        let clock = Clock()
        let engine = makeEngine([.floss, .brush], clock: clock)
        var completed: [BrushingStage] = []
        engine.onStageComplete = { completed.append($0) }
        engine.start()
        defer { engine.stop() }

        XCTAssertFalse(engine.isCurrentStageTimed)
        clock.advance(500)
        engine.debugTick()
        XCTAssertEqual(engine.phase, .stage, "untimed stages never finish on their own")
        XCTAssertEqual(engine.currentStage, .floss)
        XCTAssertEqual(engine.elapsedInStep, 500, accuracy: 0.01)

        engine.pause()
        XCTAssertFalse(engine.isPaused, "untimed stages cannot be paused")

        engine.skipStage() // the Next button
        XCTAssertEqual(completed, [.floss])
        XCTAssertEqual(engine.phase, .stage, "no celebration screen for untimed stages")
        XCTAssertEqual(engine.currentStage, .brush)
        XCTAssertEqual(engine.elapsedInStep, 0, accuracy: 0.01)
    }

    func testSkipStageAndFinishRecordsSession() {
        let clock = Clock()
        let engine = makeEngine([.floss, .brush], clock: clock)
        engine.start()
        defer { engine.stop() }

        engine.skipStage()
        XCTAssertEqual(engine.currentStage, .brush)
        engine.skipStage()
        XCTAssertEqual(engine.phase, .stageComplete, "timed stages celebrate")
        engine.continueAfterStageComplete()
        XCTAssertEqual(engine.phase, .brushCheck)
        var finished = false
        engine.onFinished = { finished = true }
        engine.finish()
        XCTAssertTrue(finished)
        let session = engine.makeSession()
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.completedStages, [.floss, .brush])
    }

    func testBrushingIntervalRecordedForHealth() {
        let clock = Clock()
        let engine = makeEngine([.floss, .brush, .mouthwash], clock: clock)
        engine.start()
        defer { engine.stop() }

        clock.advance(40)
        engine.skipStage()                       // floss → brush starts at +40
        let brushStart = clock.now
        clock.advance(135)                       // full brushing
        engine.debugTick()
        XCTAssertEqual(engine.phase, .stageComplete)
        let session = engine.makeSession()
        XCTAssertEqual(session.brushingInterval?.start, brushStart)
        XCTAssertEqual(session.brushingInterval?.duration ?? 0, 135, accuracy: 0.01)
    }

    func testNoBrushingIntervalWhenBrushingNotCompleted() {
        let clock = Clock()
        let engine = makeEngine([.brush], clock: clock)
        engine.start()
        defer { engine.stop() }
        clock.advance(20)
        engine.debugTick()
        XCTAssertNil(engine.makeSession().brushingInterval)
    }

    func testEmptyStagesGoesStraightToBrushCheck() {
        let engine = makeEngine([], clock: Clock())
        XCTAssertEqual(engine.phase, .brushCheck)
    }

    func testBrushCheckSkippedWhenNotDue() {
        let clock = Clock()
        let engine = RoutineEngine(stages: [.mouthwash], slot: .night, includesBrushCheck: false, now: { clock.now })
        var finished = false
        engine.onFinished = { finished = true }
        engine.start()
        defer { engine.stop() }
        engine.skipStage()
        XCTAssertEqual(engine.phase, .stageComplete)
        engine.continueAfterStageComplete()
        XCTAssertEqual(engine.phase, .finished)
        XCTAssertTrue(finished)
    }

    func testOlderSettingsWithoutNewKeysStillDecode() throws {
        let legacy = """
        {"morningStages":["floss","brush"],"nightStages":["brush"],"remindersEnabled":false,
         "morningReminderMinutes":420,"nightReminderMinutes":1260,"soundEnabled":true,"hapticsEnabled":false}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppSettings.self, from: legacy)
        XCTAssertEqual(decoded.orderedStages(for: .morning), [.floss, .brush])
        XCTAssertFalse(decoded.remindersEnabled)
        XCTAssertEqual(decoded.morningReminderMinutes, 420)
        XCTAssertTrue(decoded.kidsMode, "missing key falls back to the default (kids mode on)")
        XCTAssertFalse(decoded.healthSyncEnabled)
        XCTAssertNil(decoded.lastBrushCheckOn)
    }

    func testBrushCheckDueOnceAWeek() {
        var settings = AppSettings()
        let cal = Calendar.current
        let now = Date()
        XCTAssertTrue(settings.isBrushCheckDue(asOf: now), "never checked → due")
        settings.lastBrushCheckOn = now
        XCTAssertFalse(settings.isBrushCheckDue(asOf: now))
        settings.lastBrushCheckOn = cal.date(byAdding: .day, value: -6, to: now)
        XCTAssertFalse(settings.isBrushCheckDue(asOf: now))
        settings.lastBrushCheckOn = cal.date(byAdding: .day, value: -7, to: now)
        XCTAssertTrue(settings.isBrushCheckDue(asOf: now))
    }
}
