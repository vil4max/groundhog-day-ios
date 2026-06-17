import SwiftUI

struct RootView: View {
    @Bindable var storage: EventDateStorage
    let feedback: FeedbackService
    let scheduler: NotificationScheduler

    @Environment(\.scenePhase) private var scenePhase
    @State private var showPermissionSheet = false
    @State private var skippedPermissionThisSession = false
    @State private var permissionPresentationTask: Task<Void, Never>?

    private let permissionPresentationDelay: Duration = .seconds(8)

    var body: some View {
        Group {
            if storage.hasEvent {
                NavigationStack {
                    CountdownView(storage: storage, feedback: feedback, scheduler: scheduler)
                }
            } else {
                EventDatePickerView(
                    storage: storage,
                    feedback: feedback,
                    scheduler: scheduler
                ) {
                    AppLog.lifecycle.info("Onboarding completed; permission sheet scheduled")
                    schedulePermissionPresentation()
                }
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            NotificationPermissionSheet(
                scheduler: scheduler,
                isPresented: $showPermissionSheet,
                onCompleted: {
                    skippedPermissionThisSession = true
                    AppLog.lifecycle.info("Permission sheet dismissed for this session")
                }
            )
        }
        .task {
            AppLog.lifecycle.info("Root view appeared")
            await scheduler.rescheduleAll()
            if storage.hasEvent {
                schedulePermissionPresentation()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            AppLog.lifecycle.debug("Scene phase \(String(describing: oldPhase), privacy: .public) → \(String(describing: newPhase), privacy: .public)")
            if oldPhase == .background, newPhase == .active {
                Task { await scheduler.rescheduleAll() }
                if storage.hasEvent {
                    schedulePermissionPresentation()
                }
            }
            if newPhase == .background {
                permissionPresentationTask?.cancel()
                skippedPermissionThisSession = false
            }
        }
        .onDisappear {
            permissionPresentationTask?.cancel()
        }
    }

    private func schedulePermissionPresentation() {
        permissionPresentationTask?.cancel()
        permissionPresentationTask = Task {
            await presentPermissionSheetIfNeeded()
        }
    }

    private func presentPermissionSheetIfNeeded() async {
        guard storage.hasEvent else {
            AppLog.lifecycle.debug("Permission sheet skipped: no saved event")
            return
        }
        let status = await scheduler.authorizationStatus()
        guard status != .authorized, status != .provisional else {
            AppLog.lifecycle.debug("Permission sheet skipped: status \(String(describing: status), privacy: .public)")
            return
        }
        if skippedPermissionThisSession {
            AppLog.lifecycle.debug("Permission sheet skipped: dismissed this session")
            return
        }
        AppLog.lifecycle.info("Permission sheet scheduled in \(permissionPresentationDelay)")
        try? await Task.sleep(for: permissionPresentationDelay)
        guard !Task.isCancelled else { return }
        guard storage.hasEvent, !skippedPermissionThisSession else { return }
        let latestStatus = await scheduler.authorizationStatus()
        guard latestStatus != .authorized, latestStatus != .provisional else { return }
        AppLog.lifecycle.info("Presenting permission sheet")
        showPermissionSheet = true
    }
}
