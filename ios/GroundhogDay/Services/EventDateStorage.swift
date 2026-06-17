import Foundation
import Observation

@MainActor
@Observable
final class EventDateStorage {
    private enum Keys {
        static let eventTargetDate = "eventTargetDate"
        static let eventLabel = "eventLabel"
        static let notificationsEnabled = "notificationsEnabled"
        static let dailyReminderMessage = "dailyReminderMessage"
        static let eventArrivedMessage = "eventArrivedMessage"
        static let needsFullRevealAnimation = "needsFullRevealAnimation"
        static let lastModifiedAt = "lastModifiedAt"
    }

    private let defaults: UserDefaults
    private let cloudSync: any CloudSyncing

    var eventTargetDate: Date?
    var eventLabel: String?
    var notificationsEnabled: Bool
    var dailyReminderMessage: String?
    var eventArrivedMessage: String?
    var needsFullRevealAnimation: Bool

    var hasEvent: Bool {
        eventTargetDate != nil
    }

    var isEventPassed: Bool {
        guard let eventTargetDate else { return false }
        return CountdownCalculator.isEventPassed(eventDate: eventTargetDate)
    }

    init(defaults: UserDefaults = .standard, cloudSync: any CloudSyncing) {
        self.defaults = defaults
        self.cloudSync = cloudSync
        if let loadedDate = defaults.object(forKey: Keys.eventTargetDate) as? Date {
            if loadedDate > EventDateBounds.latestSelectableDate() {
                let clamped = EventDateBounds.clamp(loadedDate)
                eventTargetDate = clamped
                defaults.set(clamped, forKey: Keys.eventTargetDate)
            } else {
                eventTargetDate = loadedDate
            }
        }
        eventLabel = defaults.string(forKey: Keys.eventLabel)
        notificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        dailyReminderMessage = defaults.string(forKey: Keys.dailyReminderMessage)
        eventArrivedMessage = defaults.string(forKey: Keys.eventArrivedMessage)
        needsFullRevealAnimation = defaults.object(forKey: Keys.needsFullRevealAnimation) as? Bool ?? true

        cloudSync.startObserving { [weak self] in
            Task { @MainActor in
                await self?.importFromCloudIfNeeded()
            }
        }
        Task { await importFromCloudIfNeeded() }
    }

    func save(eventDate: Date, label: String?) {
        eventTargetDate = EventDateBounds.clamp(eventDate)
        eventLabel = sanitized(label)
        needsFullRevealAnimation = true
        AppLog.storage.info("Saved event date \(eventDate, privacy: .public) label \(label ?? "nil", privacy: .public)")
        persist()
    }

    func saveLabel(_ label: String?) {
        eventLabel = sanitized(label)
        AppLog.storage.debug("Updated label \(label ?? "nil", privacy: .public)")
        persist()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        AppLog.storage.info("Notifications enabled: \(enabled, privacy: .public)")
        persist()
    }

    func saveDailyReminderMessage(_ message: String?) {
        dailyReminderMessage = sanitized(message)
        AppLog.storage.debug("Updated daily reminder message")
        persist()
    }

    func saveEventArrivedMessage(_ message: String?) {
        eventArrivedMessage = sanitized(message)
        AppLog.storage.debug("Updated event-arrived message")
        persist()
    }

    func markRevealAnimationCompleted() {
        needsFullRevealAnimation = false
        defaults.set(false, forKey: Keys.needsFullRevealAnimation)
    }

    func requestFullRevealAnimation() {
        needsFullRevealAnimation = true
        defaults.set(true, forKey: Keys.needsFullRevealAnimation)
    }

    private func sanitized(_ label: String?) -> String? {
        label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private func persist() {
        if let eventTargetDate {
            defaults.set(eventTargetDate, forKey: Keys.eventTargetDate)
        } else {
            defaults.removeObject(forKey: Keys.eventTargetDate)
        }
        if let eventLabel {
            defaults.set(eventLabel, forKey: Keys.eventLabel)
        } else {
            defaults.removeObject(forKey: Keys.eventLabel)
        }
        defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        if let dailyReminderMessage {
            defaults.set(dailyReminderMessage, forKey: Keys.dailyReminderMessage)
        } else {
            defaults.removeObject(forKey: Keys.dailyReminderMessage)
        }
        if let eventArrivedMessage {
            defaults.set(eventArrivedMessage, forKey: Keys.eventArrivedMessage)
        } else {
            defaults.removeObject(forKey: Keys.eventArrivedMessage)
        }
        defaults.set(needsFullRevealAnimation, forKey: Keys.needsFullRevealAnimation)

        let modifiedAt = Date().timeIntervalSince1970
        defaults.set(modifiedAt, forKey: Keys.lastModifiedAt)

        let snapshot = EventSnapshot(
            eventTargetDate: eventTargetDate,
            eventLabel: eventLabel,
            notificationsEnabled: notificationsEnabled,
            dailyReminderMessage: dailyReminderMessage,
            eventArrivedMessage: eventArrivedMessage,
            lastModifiedAt: modifiedAt
        )
        Task {
            await cloudSync.push(snapshot: snapshot)
        }
    }

    private func importFromCloudIfNeeded() async {
        guard FeatureFlags.iCloudSyncEnabled, let remote = await cloudSync.pull() else { return }
        let localModified = defaults.double(forKey: Keys.lastModifiedAt)
        guard remote.lastModifiedAt >= localModified else { return }

        eventTargetDate = remote.eventTargetDate.map { EventDateBounds.clamp($0) }
        eventLabel = remote.eventLabel
        notificationsEnabled = remote.notificationsEnabled
        dailyReminderMessage = remote.dailyReminderMessage
        eventArrivedMessage = remote.eventArrivedMessage
        persist()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
