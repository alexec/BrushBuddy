import SwiftUI

struct RoutineLaunch: Identifiable {
    let slot: DaySlot
    var id: String { slot.rawValue }
}

struct HomeView: View {
    @Environment(BrushStore.self) private var store
    @State private var showSettings = false
    @State private var launch: RoutineLaunch?
    @State private var now = Date()
    @State private var chosenSlot: DaySlot?

    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var slot: DaySlot { chosenSlot ?? DaySlot.slot(for: now) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    hero
                    routineCard
                    WeekHistoryView(now: now)
                    nudges
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 32)
            }
            .background(Theme.background(tint: Theme.accent))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fullScreenCover(item: $launch) { launch in
                RoutineView(slot: launch.slot,
                            stages: store.settings.orderedStages(for: launch.slot),
                            includesBrushCheck: store.settings.isBrushCheckDue(asOf: now))
            }
            .onReceive(clock) { now = $0 }
            .onAppear {
                #if DEBUG
                switch DemoOptions.current.screen {
                case "routine": launch = RoutineLaunch(slot: slot)
                case "settings": showSettings = true
                default: break
                }
                #endif
            }
        }
    }

    // MARK: - Hero

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 4..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var hero: some View {
        let morningDone = store.status(on: now, slot: .morning) == .complete
        let nightDone = store.status(on: now, slot: .night) == .complete
        return HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(greeting)
                    .font(.display(36))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 8) {
                    statusDot(.morning, done: morningDone)
                    statusDot(.night, done: nightDone)
                }
            }
            Spacer(minLength: 0)
            ToothMascot(size: 88, mood: (morningDone && nightDone) ? .cheering : .happy)
        }
        .padding(.top, 10)
    }

    private func statusDot(_ s: DaySlot, done: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : s.symbol)
                .font(.caption.weight(.bold))
            Text(s.title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(done ? Theme.good : Theme.textTertiary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(done ? Theme.good.opacity(0.14) : Theme.surface, in: Capsule())
    }

    // MARK: - Routine card

    private var routineCard: some View {
        let stages = store.settings.orderedStages(for: slot)
        let total = stages.filter(\.isTimed).reduce(0) { $0 + $1.totalDuration }
        let hasUntimed = stages.contains { !$0.isTimed }
        return VStack(spacing: 20) {
            HStack {
                slotToggle
                Spacer()
                Text(stages.isEmpty ? "—" : (hasUntimed && total > 0 ? "\(total.minutesRounded) timed" : (total > 0 ? total.minutesRounded : "untimed")))
                    .font(.display(15, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            if stages.isEmpty {
                Text("Every stage is off for the \(slot.title.lowercased()). Turn some on — we recommend the full routine.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Open Settings") { showSettings = true }
                    .buttonStyle(GhostButtonStyle())
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(stages.enumerated()), id: \.element) { index, stage in
                        IconDisc(symbol: stage.symbol, color: stage.color, size: 48)
                        if index < stages.count - 1 {
                            Rectangle().fill(Theme.stroke).frame(height: 1).frame(maxWidth: .infinity)
                        }
                    }
                }
                Button {
                    Haptics.tap()
                    launch = RoutineLaunch(slot: slot)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(PillButtonStyle(color: Theme.accent))
            }
        }
        .glass(padding: 20)
    }

    private var slotToggle: some View {
        HStack(spacing: 2) {
            ForEach(DaySlot.allCases) { s in
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { chosenSlot = s }
                } label: {
                    Label(s.title, systemImage: s.symbol)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(slot == s ? Theme.surfaceRaised : .clear, in: Capsule())
                        .foregroundStyle(slot == s ? Theme.text : Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke))
    }

    // MARK: - Nudges

    @ViewBuilder
    private var nudges: some View {
        let disabled = store.settings.disabledStages(for: slot)
        VStack(spacing: 10) {
            if !disabled.isEmpty {
                nudge(symbol: "heart.text.square.fill", tint: Theme.warn,
                      text: "\(disabled.map(\.title).formatted(.list(type: .and))) off for the \(slot.title.lowercased()). Best practice is the full routine, twice a day.") {
                    showSettings = true
                }
            }
            if store.settings.brushNeedsReplacing(asOf: now), let age = store.settings.brushAgeDays(asOf: now) {
                nudge(symbol: "exclamationmark.triangle.fill", tint: Theme.warn,
                      text: "Your toothbrush is \(age) days old. Time for a fresh one — worn bristles clean far less well.") { // [ADA-care]
                    showSettings = true
                }
            }
        }
    }

    private func nudge(symbol: String, tint: Color, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol).foregroundStyle(tint).padding(.top, 1)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .glass(padding: 14, radius: 18)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView().environment(BrushStore.inMemory())
}
