import Foundation
import HealthKit

/// Writes completed brushing sessions to Apple Health as Tooth Brushing events.
@MainActor
final class HealthManager {
    static let shared = HealthManager()

    private let store = HKHealthStore()
    private let toothbrushing = HKCategoryType(.toothbrushingEvent)

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var isSharingAuthorized: Bool {
        isAvailable && store.authorizationStatus(for: toothbrushing) == .sharingAuthorized
    }

    var isSharingDenied: Bool {
        isAvailable && store.authorizationStatus(for: toothbrushing) == .sharingDenied
    }

    /// Ask for permission to write Tooth Brushing events. Returns whether we may write.
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [toothbrushing], read: [])
        } catch {
            return false
        }
        return isSharingAuthorized
    }

    /// Save the brushing stage of a session. Silently does nothing if the
    /// session has no completed brushing or Health access isn't granted.
    func log(_ session: BrushingSession) async {
        guard isSharingAuthorized, let interval = session.brushingInterval else { return }
        let sample = HKCategorySample(
            type: toothbrushing,
            value: HKCategoryValue.notApplicable.rawValue,
            start: interval.start,
            end: interval.end,
            metadata: [HKMetadataKeyExternalUUID: session.id.uuidString]
        )
        try? await store.save(sample)
    }
}
