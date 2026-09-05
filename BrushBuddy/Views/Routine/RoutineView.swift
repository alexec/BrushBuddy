import SwiftUI

/// Full-screen flow through the enabled stages, then the toothbrush check
/// and the completion screen.
struct RoutineView: View {
    @Environment(BrushStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.visualStyle) private var style

    @State private var engine: RoutineEngine
    @State private var showExitConfirm = false
    @State private var recorded = false

    init(slot: DaySlot, stages: [BrushingStage], includesBrushCheck: Bool) {
        var stages = stages
        var includesBrushCheck = includesBrushCheck
        #if DEBUG
        if let from = DemoOptions.current.stage, let idx = stages.firstIndex(of: from) {
            stages = Array(stages[idx...])
        }
        if DemoOptions.current.phase == "brushCheck" { includesBrushCheck = true }
        #endif
        _engine = State(initialValue: RoutineEngine(stages: stages, slot: slot, includesBrushCheck: includesBrushCheck))
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            switch engine.phase {
            case .stage, .stageComplete:
                if let stage = engine.currentStage {
                    StageView(engine: engine, onExit: { showExitConfirm = true })
                        .id(stage)
                        .transition(.opacity)
                    if engine.phase == .stageComplete {
                        StageCompleteOverlay(engine: engine)
                            .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    }
                }
            case .brushCheck:
                ToothbrushCheckView(onDone: {
                    store.settings.lastBrushCheckOn = Date()
                    engine.finish()
                })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .finished:
                RoutineCompleteView(session: engine.makeSession(), onClose: { dismiss() })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: engine.phase)
        .statusBarHidden(false)
        .onAppear(perform: wireUp)
        .onDisappear {
            engine.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { engine.start() }
        }
        .confirmationDialog("Stop this routine?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Stop and save progress", role: .destructive) {
                recordIfNeeded()
                dismiss()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text(engine.completedStages.isEmpty
                 ? "Nothing's been completed yet, so nothing will be recorded."
                 : "We'll record the \(engine.completedStages.count) stage\(engine.completedStages.count == 1 ? "" : "s") you finished as a partial routine.")
        }
    }

    private var background: some View {
        let tint: Color = {
            if let stage = engine.currentStage, engine.phase == .stage || engine.phase == .stageComplete { return stage.color }
            return Theme.accent
        }()
        return Theme.background(tint: tint, style: style)
            .animation(.easeInOut(duration: 0.6), value: engine.stageIndex)
    }

    private func wireUp() {
        UIApplication.shared.isIdleTimerDisabled = true
        engine.onStepComplete = { _ in
            SoundPlayer.shared.play(.stepDone)
            Haptics.stepComplete()
        }
        engine.onStageComplete = { _ in
            SoundPlayer.shared.play(.stageDone)
            Haptics.stageComplete()
        }
        engine.onFinished = {
            SoundPlayer.shared.play(.routineDone)
            Haptics.stageComplete()
            recordIfNeeded()
        }
        engine.start()
        #if DEBUG
        applyDemoPhase()
        #endif
    }

    #if DEBUG
    private func applyDemoPhase() {
        switch DemoOptions.current.phase {
        case "stageComplete":
            engine.skipStage()
        case "brushCheck", "finished":
            while engine.phase == .stage {
                engine.skipStage()
                engine.continueAfterStageComplete()
            }
            if DemoOptions.current.phase == "finished", engine.phase == .brushCheck { engine.finish() }
        default:
            break
        }
    }
    #endif

    private func recordIfNeeded() {
        guard !recorded, !engine.completedStages.isEmpty else { return }
        recorded = true
        let session = engine.makeSession()
        store.record(session)
        if store.settings.healthSyncEnabled {
            Task { await HealthManager.shared.log(session) }
        }
    }
}

#Preview {
    RoutineView(slot: .morning, stages: BrushingStage.allCases, includesBrushCheck: true)
        .environment(BrushStore.inMemory())
}
