import SwiftUI

/// One running stage: title, animation, big countdown, one-line tip, controls.
struct StageView: View {
    var engine: RoutineEngine
    var onExit: () -> Void

    var body: some View {
        guard let stage = engine.currentStage, let step = engine.currentStep else {
            return AnyView(EmptyView())
        }
        return AnyView(
            VStack(spacing: 0) {
                topBar(stage: stage)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(step.title)
                            .font(.display(34))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if stage.isTimed {
                            StepSegmentBar(steps: stage.steps, currentIndex: engine.stepIndex, currentProgress: engine.stepProgress, color: stage.color)
                        }
                    }
                    .padding(.top, 12)

                    animation(for: stage, step: step)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .glass(padding: 6, radius: 28)
                        .overlay(alignment: .topTrailing) {
                            if engine.isPaused {
                                Text("Paused")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.bg)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(stage.color, in: Capsule())
                                    .padding(12)
                            }
                        }

                    if stage.isTimed {
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(Int(engine.stepRemaining.rounded(.up)))")
                                .font(.display(64))
                                .monospacedDigit()
                                .foregroundStyle(stage.color)
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.snappy, value: Int(engine.stepRemaining.rounded(.up)))
                                .frame(minWidth: 84, alignment: .leading)
                            Text(step.instruction)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(Int(engine.stepRemaining.rounded(.up))) seconds left. \(step.instruction)")
                    } else {
                        Text(step.instruction)
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    TipCarousel(tips: stage.tips, color: stage.color)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                }

                controls(stage: stage)
                    .padding(.bottom, 10)
            }
        )
    }

    // MARK: - Pieces

    private func topBar(stage: BrushingStage) -> some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 40, height: 40)
                    .background(Theme.surfaceRaised, in: Circle())
            }
            .accessibilityLabel("Stop routine")
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: stage.symbol)
                Text(stage.title.uppercased())
                if stage.isTimed && stage.steps.count > 1 {
                    Text("·").foregroundStyle(Theme.textTertiary)
                    Text("\(engine.stepIndex + 1)/\(stage.steps.count)")
                }
            }
            .font(.caption.weight(.bold))
            .tracking(1)
            .foregroundStyle(stage.color)
            .accessibilityLabel("\(stage.title), step \(engine.stepIndex + 1) of \(stage.steps.count). Stage \(engine.stageIndex + 1) of \(engine.stages.count)")
            Spacer()
            Text(stage.isTimed ? engine.stageRemaining.shortClock : "")
                .font(.display(15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 44, alignment: .trailing)
                .accessibilityLabel(stage.isTimed ? "\(Int(engine.stageRemaining)) seconds left in this stage" : "")
        }
    }

    @ViewBuilder
    private func animation(for stage: BrushingStage, step: StageStep) -> some View {
        switch stage {
        case .waterPick: WaterPickAnimation(zone: step.zone)
        case .floss: FlossAnimation(zone: step.zone)
        case .brush: BrushAnimation(zone: step.zone)
        case .mouthwash: MouthwashAnimation()
        }
    }

    @ViewBuilder
    private func controls(stage: BrushingStage) -> some View {
        if stage.isTimed {
            timedControls(stage: stage)
        } else {
            Button {
                Haptics.tap()
                engine.skipStage()
            } label: {
                Label(engine.nextStage.map { "Next: \($0.title)" } ?? "Done", systemImage: "arrow.right")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .buttonStyle(PillButtonStyle(color: stage.color))
            .padding(.horizontal, 20)
            .accessibilityHint("Finishes this stage when you're done")
        }
    }

    private func timedControls(stage: BrushingStage) -> some View {
        let isLastStep = engine.stepIndex >= stage.steps.count - 1
        return HStack {
            Color.clear.frame(width: 56, height: 56)
            Spacer()
            Button {
                Haptics.tap()
                engine.togglePause()
            } label: {
                Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(RoundButtonStyle(color: stage.color, size: 76))
            .accessibilityLabel(engine.isPaused ? "Resume" : "Pause")
            Spacer()
            Menu {
                Button {
                    Haptics.tap()
                    engine.skipStep()
                } label: {
                    Label(isLastStep ? "Finish this stage" : "Skip this step", systemImage: "forward.fill")
                }
                if !isLastStep {
                    Button {
                        Haptics.tap()
                        engine.skipStage()
                    } label: {
                        Label("Skip rest of \(stage.title.lowercased())", systemImage: "forward.end.fill")
                    }
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 56, height: 56)
                    .background(Theme.surfaceRaised, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.stroke))
            }
            .accessibilityLabel("Skip options")
        }
        .padding(.horizontal, 36)
    }
}

/// Label with the icon after the text.
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.title
            configuration.icon
        }
    }
}
