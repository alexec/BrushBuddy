import Foundation
import Observation

/// Drives a run through the enabled stages: timing, step/stage advancement,
/// pause and skip. Uses the wall clock so time keeps counting if the phone
/// locks mid-brush.
@Observable
@MainActor
final class RoutineEngine {
    enum Phase: Equatable {
        case stage            // a timed step is running (or paused)
        case stageComplete    // celebrating; waiting to move on
        case brushCheck       // final toothbrush health reminder
        case finished
    }

    let stages: [BrushingStage]
    let slot: DaySlot
    let startedAt: Date
    /// Whether to show the toothbrush check before finishing (once a week).
    let includesBrushCheck: Bool

    private(set) var stageIndex = 0
    private(set) var stepIndex = 0
    private(set) var phase: Phase
    private(set) var isPaused = false
    private(set) var elapsedInStep: TimeInterval = 0
    private(set) var completedStages: [BrushingStage] = []
    /// Seconds remaining before we auto-advance after a stage completes.
    private(set) var autoAdvanceRemaining: TimeInterval = 0

    /// Called when a step (e.g. a mouth quadrant) finishes on its own.
    var onStepComplete: ((StageStep) -> Void)?
    /// Called when a whole stage finishes (skipped or naturally).
    var onStageComplete: ((BrushingStage) -> Void)?
    /// Called when the whole routine is finished.
    var onFinished: (() -> Void)?

    static let autoAdvanceDelay: TimeInterval = 4

    /// Wall-clock start and end of each stage that has run.
    private(set) var stageStarts: [BrushingStage: Date] = [:]
    private(set) var stageEnds: [BrushingStage: Date] = [:]

    private var stepStartedAt: Date?
    private var pauseStartedAt: Date?
    private var stageCompleteAt: Date?
    private var timer: Timer?
    private let now: () -> Date

    init(stages: [BrushingStage], slot: DaySlot, includesBrushCheck: Bool = true, now: @escaping () -> Date = Date.init) {
        self.stages = stages
        self.slot = slot
        self.includesBrushCheck = includesBrushCheck
        self.now = now
        self.startedAt = now()
        self.phase = stages.isEmpty ? (includesBrushCheck ? .brushCheck : .finished) : .stage
    }

    // MARK: - Derived state

    var currentStage: BrushingStage? { stages.indices.contains(stageIndex) ? stages[stageIndex] : nil }
    var currentStep: StageStep? {
        guard let stage = currentStage, stage.steps.indices.contains(stepIndex) else { return nil }
        return stage.steps[stepIndex]
    }
    var nextStage: BrushingStage? { stages.indices.contains(stageIndex + 1) ? stages[stageIndex + 1] : nil }

    /// Whether the current stage counts down.
    var isCurrentStageTimed: Bool { currentStage?.isTimed ?? true }

    var stepProgress: Double {
        guard let step = currentStep, step.duration > 0 else { return 0 }
        return min(1, max(0, elapsedInStep / step.duration))
    }

    var stepRemaining: TimeInterval {
        guard let step = currentStep else { return 0 }
        return max(0, step.duration - elapsedInStep)
    }

    var stageElapsed: TimeInterval {
        guard let stage = currentStage else { return 0 }
        let before = stage.steps.prefix(stepIndex).reduce(0) { $0 + $1.duration }
        return before + elapsedInStep
    }

    var stageProgress: Double {
        guard let stage = currentStage, stage.totalDuration > 0 else { return 0 }
        return min(1, stageElapsed / stage.totalDuration)
    }

    var stageRemaining: TimeInterval {
        guard let stage = currentStage else { return 0 }
        return max(0, stage.totalDuration - stageElapsed)
    }

    var totalDuration: TimeInterval { stages.reduce(0) { $0 + $1.totalDuration } }

    var routineProgress: Double {
        guard totalDuration > 0 else { return 0 }
        let before = stages.prefix(stageIndex).reduce(0) { $0 + $1.totalDuration }
        return min(1, (before + (phase == .stageComplete ? (currentStage?.totalDuration ?? 0) : stageElapsed)) / totalDuration)
    }

    // MARK: - Control

    func start() {
        guard timer == nil else { return }
        if phase == .stage, stepStartedAt == nil {
            stepStartedAt = now()
            if let stage = currentStage { stageStarts[stage] = now() }
        }
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    func pause() {
        guard phase == .stage, !isPaused, isCurrentStageTimed else { return }
        isPaused = true
        pauseStartedAt = now()
    }

    func resume() {
        guard isPaused else { return }
        if let pausedAt = pauseStartedAt, let started = stepStartedAt {
            stepStartedAt = started.addingTimeInterval(now().timeIntervalSince(pausedAt))
        }
        pauseStartedAt = nil
        isPaused = false
    }

    /// Jump to the next step, or finish the stage if this was the last one.
    func skipStep() {
        guard phase == .stage else { return }
        advanceStep()
    }

    /// Mark the current stage done and move on. For untimed stages this is the
    /// "Next" button; for timed stages it skips what's left.
    func skipStage() {
        guard phase == .stage, currentStage != nil else { return }
        completeCurrentStage()
    }

    /// From the celebration screen, proceed to the next stage or the brush check.
    func continueAfterStageComplete() {
        guard phase == .stageComplete else { return }
        stageCompleteAt = nil
        if stageIndex + 1 < stages.count {
            stageIndex += 1
            stepIndex = 0
            elapsedInStep = 0
            isPaused = false
            pauseStartedAt = nil
            stepStartedAt = now()
            if let stage = currentStage { stageStarts[stage] = now() }
            phase = .stage
        } else if includesBrushCheck {
            phase = .brushCheck
        } else {
            finishRoutine()
        }
    }

    /// From the toothbrush check, finish the routine.
    func finish() {
        guard phase == .brushCheck else { return }
        finishRoutine()
    }

    private func finishRoutine() {
        phase = .finished
        stop()
        onFinished?()
    }

    /// Build the session record for what actually happened.
    func makeSession() -> BrushingSession {
        BrushingSession(startedAt: startedAt, endedAt: now(), slot: slot, plannedStages: stages, completedStages: completedStages,
                        brushingStart: stageStarts[.brush], brushingEnd: completedStages.contains(.brush) ? stageEnds[.brush] : nil)
    }

    // MARK: - Internals

    /// Runs one clock tick immediately. Exposed for tests.
    func debugTick() { tick() }

    private func tick() {
        switch phase {
        case .stage:
            guard !isPaused, let started = stepStartedAt else { return }
            if !isCurrentStageTimed {
                // Untimed stages just count up until the user taps Next.
                elapsedInStep = now().timeIntervalSince(started)
                return
            }
            var anchor = started
            var elapsed = now().timeIntervalSince(anchor)
            // Catch up if we were in the background across one or more steps.
            while let step = currentStep, elapsed >= step.duration {
                elapsed -= step.duration
                anchor = anchor.addingTimeInterval(step.duration)
                stepStartedAt = anchor
                advanceStep(naturally: true)
                if phase != .stage { return }
            }
            elapsedInStep = elapsed
        case .stageComplete:
            guard let at = stageCompleteAt else { return }
            // Mouthwash needs the user to go pour a cup first, so never auto-advance
            // into it — wait for a deliberate tap on Continue.
            guard nextStage != .mouthwash else { return }
            let remaining = RoutineEngine.autoAdvanceDelay - now().timeIntervalSince(at)
            autoAdvanceRemaining = max(0, remaining)
            if remaining <= 0 { continueAfterStageComplete() }
        case .brushCheck, .finished:
            break
        }
    }

    private func advanceStep(naturally: Bool = false) {
        guard let stage = currentStage else { return }
        if naturally, let step = currentStep { onStepComplete?(step) }
        if stepIndex + 1 < stage.steps.count {
            stepIndex += 1
            elapsedInStep = 0
            // When advancing naturally, tick() has already re-anchored stepStartedAt.
            if !naturally { stepStartedAt = now() }
        } else {
            completeCurrentStage()
        }
    }

    private func completeCurrentStage() {
        guard let stage = currentStage else { return }
        completedStages.append(stage)
        stageEnds[stage] = now()
        elapsedInStep = currentStep?.duration ?? 0
        isPaused = false
        pauseStartedAt = nil
        phase = .stageComplete
        stageCompleteAt = now()
        autoAdvanceRemaining = RoutineEngine.autoAdvanceDelay
        onStageComplete?(stage)
        // Untimed stages end with a deliberate tap, so skip the celebration
        // and move straight on.
        if !stage.isTimed {
            continueAfterStageComplete()
        }
    }
}
