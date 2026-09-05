import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(BrushStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsDenied = false
    @State private var showDeniedAlert = false
    @State private var showHealthDeniedAlert = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                remindersSection
                routineSection
                healthSection
                feedbackSection
                toothbrushSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await refreshAuthorization() }
            .onChange(of: store.settings.remindersEnabled) { _, _ in resync() }
            .onChange(of: store.settings.morningReminderMinutes) { _, _ in resync() }
            .onChange(of: store.settings.nightReminderMinutes) { _, _ in resync() }
            .onChange(of: store.settings.soundEnabled) { _, on in SoundPlayer.shared.isEnabled = on; if on { SoundPlayer.shared.play(.stepDone) } }
            .onChange(of: store.settings.hapticsEnabled) { _, on in Haptics.isEnabled = on; if on { Haptics.stageComplete() } }
            .onChange(of: store.settings.healthSyncEnabled) { _, on in
                guard on else { return }
                Task {
                    let ok = await HealthManager.shared.requestAuthorization()
                    if !ok, HealthManager.shared.isSharingDenied { showHealthDeniedAlert = true }
                }
            }
            .alert("Health access is off", isPresented: $showHealthDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("To log brushing, allow Brushwise to write Tooth Brushing data in the Health app: Health → Profile → Apps → Brushwise.")
            }
            .alert("Notifications are off", isPresented: $showDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                Button("Not now", role: .cancel) {}
            } message: {
                Text("Brushwise can't remind you until notifications are allowed in the iOS Settings app.")
            }
        }
    }

    // MARK: - Sections

    private var remindersSection: some View {
        @Bindable var store = store
        return Section {
            Toggle(isOn: $store.settings.remindersEnabled) {
                Label("Daily reminders", systemImage: "bell.badge.fill")
            }
            if store.settings.remindersEnabled {
                DatePicker(selection: reminderBinding(for: .morning), displayedComponents: .hourAndMinute) {
                    Label("Morning", systemImage: DaySlot.morning.symbol)
                }
                DatePicker(selection: reminderBinding(for: .night), displayedComponents: .hourAndMinute) {
                    Label("Night", systemImage: DaySlot.night.symbol)
                }
                if notificationsDenied {
                    Button {
                        showDeniedAlert = true
                    } label: {
                        Label("Notifications are blocked — tap to fix", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.warn)
                    }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A nudge twice a day. Brushing morning and night — with two minutes each time — is the routine dentists recommend.")
        }
    }

    private var routineSection: some View {
        Section {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Stage").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    ForEach(DaySlot.allCases) { slot in
                        Image(systemName: slot.symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(slot == .morning ? Theme.warn : Theme.accent)
                            .frame(width: 52)
                            .accessibilityLabel(slot.title)
                    }
                }
                ForEach(BrushingStage.recommendedOrder) { stage in
                    GridRow {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stage.title)
                                Text(stage.isTimed ? stage.totalDuration.shortClock : "as long as it takes").font(.caption2).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: stage.symbol).foregroundStyle(stage.color)
                        }
                        Spacer()
                        ForEach(DaySlot.allCases) { slot in
                            Toggle(isOn: stageBinding(stage, slot)) { EmptyView() }
                                .labelsHidden()
                                .frame(width: 52)
                                .accessibilityLabel("\(stage.title) in the \(slot.title.lowercased())")
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Your routine")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose what you do in the morning and at night. The full routine is what we recommend — but a shorter routine you'll actually do beats a perfect one you skip.")
                ForEach(disabledAnywhere) { stage in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Theme.warn)
                        Text(stage.recommendationWhenDisabled)
                    }
                }
            }
        }
    }

    private var disabledAnywhere: [BrushingStage] {
        BrushingStage.recommendedOrder.filter { !store.settings.isEnabled($0, in: .morning) || !store.settings.isEnabled($0, in: .night) }
    }

    @ViewBuilder
    private var healthSection: some View {
        @Bindable var store = store
        if HealthManager.shared.isAvailable {
            Section {
                Toggle(isOn: $store.settings.healthSyncEnabled) {
                    Label("Log to Apple Health", systemImage: "heart.fill")
                }
            } header: {
                Text("Apple Health")
            } footer: {
                Text("Each completed brushing is saved to the Health app as a Tooth Brushing event with its start and end time.")
            }
        }
    }

    private var feedbackSection: some View {
        @Bindable var store = store
        return Section("Feedback") {
            Toggle(isOn: $store.settings.soundEnabled) {
                Label("Sounds", systemImage: "speaker.wave.2.fill")
            }
            Toggle(isOn: $store.settings.hapticsEnabled) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
        }
    }

    private var toothbrushSection: some View {
        @Bindable var store = store
        return Section {
            if let replaced = store.settings.brushReplacedOn {
                DatePicker(selection: Binding(get: { replaced }, set: { store.settings.brushReplacedOn = $0 }), in: ...Date(), displayedComponents: .date) {
                    Label("Last replaced", systemImage: "calendar")
                }
                if let age = store.settings.brushAgeDays() {
                    LabeledContent("Age", value: "\(age) day\(age == 1 ? "" : "s")")
                        .foregroundStyle(store.settings.brushNeedsReplacing() ? Theme.warn : .primary)
                }
            } else {
                Text("Tell us when you last got a new brush and we'll remind you when it's due.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button {
                store.settings.brushReplacedOn = Date()
                Haptics.tap()
            } label: {
                Label("I replaced my brush today", systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Text("Toothbrush")
        } footer: {
            Text("Replace your brush or brush head every \(AppSettings.brushLifetimeDays) days, or sooner if the bristles are frayed or splayed.")
        }
    }

    private var aboutSection: some View {
        Section {
            ForEach(Array(BrushingStage.recommendedOrder.enumerated()), id: \.element) { index, stage in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.bg)
                        .frame(width: 22, height: 22)
                        .background(stage.color, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.title)
                        Text(stage.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        } header: {
            Text("Why this order?")
        } footer: {
            Text(DentalAdvice.routineOrderExplanation + "\n\n" + DentalAdvice.disclaimer)
        }
    }

    // MARK: - Bindings & helpers

    private func stageBinding(_ stage: BrushingStage, _ slot: DaySlot) -> Binding<Bool> {
        Binding(
            get: { store.settings.isEnabled(stage, in: slot) },
            set: { store.settings.setEnabled($0, stage: stage, in: slot) }
        )
    }

    private func reminderBinding(for slot: DaySlot) -> Binding<Date> {
        Binding(
            get: {
                let minutes = store.settings.reminderMinutes(for: slot)
                return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.settings.setReminderMinutes((comps.hour ?? 0) * 60 + (comps.minute ?? 0), for: slot)
            }
        )
    }

    private func resync() {
        Task {
            await NotificationManager.shared.sync(with: store.settings)
            await refreshAuthorization()
            if store.settings.remindersEnabled && notificationsDenied { showDeniedAlert = true }
        }
    }

    private func refreshAuthorization() async {
        notificationsDenied = await NotificationManager.shared.authorizationStatus() == .denied
    }
}

#Preview {
    SettingsView().environment(BrushStore.inMemory())
}
