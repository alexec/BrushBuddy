import SwiftUI

/// End-of-routine reminder to check the toothbrush and know when to replace it.
struct ToothbrushCheckView: View {
    @Environment(BrushStore.self) private var store
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Quick brush check")
                            .font(.display(32))
                            .foregroundStyle(Theme.text)
                        Text("Once a week — take a look at your bristles.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 28)

                    ToothbrushHeadIllustration()
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .glass()

                    ageLine

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(DentalAdvice.toothbrushCare.prefix(3)) { tip in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.good).padding(.top, 1)
                                Text(tip.text).font(.footnote).foregroundStyle(Theme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glass()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            VStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    onDone()
                } label: {
                    Label("Bristles look good", systemImage: "checkmark")
                }
                .buttonStyle(PillButtonStyle(color: Theme.good))
                Button {
                    Haptics.tap()
                    store.settings.brushReplacedOn = Date()
                    onDone()
                } label: {
                    Label("I'm replacing it today", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(GhostButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }

    @ViewBuilder
    private var ageLine: some View {
        let age = store.settings.brushAgeDays()
        let needs = store.settings.brushNeedsReplacing()
        HStack(spacing: 12) {
            Image(systemName: needs ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                .foregroundStyle(needs ? Theme.warn : Theme.accent)
            Group {
                if let age {
                    Text(needs
                         ? "Your brush is \(age) days old — time for a new one."
                         : "Your brush is \(age) day\(age == 1 ? "" : "s") old. Replace it around day \(AppSettings.brushLifetimeDays).") // [ADA-care] 3–4 months
                } else {
                    Text("Tap “I'm replacing it today” when you start a new brush and we'll count the days.")
                }
            }
            .font(.footnote)
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .glass(padding: 14, radius: 18)
    }
}

#Preview {
    ZStack { Theme.background(tint: Theme.accent); ToothbrushCheckView(onDone: {}) }.environment(BrushStore.inMemory())
}
