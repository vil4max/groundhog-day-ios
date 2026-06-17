import SwiftUI

@main
struct GroundhogDayApp: App {
    @State private var storage: EventDateStorage
    @State private var scheduler: NotificationScheduler
    @State private var feedback: FeedbackService

    init() {
        let cloudSync: any CloudSyncing = FeatureFlags.iCloudSyncEnabled
            ? ICloudKeyValueSync()
            : NoOpCloudSync()
        let storage = EventDateStorage(cloudSync: cloudSync)
        let scheduler = NotificationScheduler(storage: storage)
        let feedback = FeedbackService()
        _storage = State(initialValue: storage)
        _scheduler = State(initialValue: scheduler)
        _feedback = State(initialValue: feedback)
    }

    var body: some Scene {
        WindowGroup {
            RootView(storage: storage, feedback: feedback, scheduler: scheduler)
                .tint(FlipClockTheme.accent)
        }
    }
}
