import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {
    enum Identifier {
        static let dailyReminderPrefix = DailyReminderPlanner.identifierPrefix
        static let legacyDailyReminder = DailyReminderPlanner.legacyIdentifier
        static let eventArrived = "event-arrived"
    }

    private let storage: EventDateStorage
    private let center = UNUserNotificationCenter.current()

    init(storage: EventDateStorage) {
        self.storage = storage
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        AppLog.notifications.info("Requesting notification authorization")
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            AppLog.notifications.info("Authorization granted: \(granted, privacy: .public)")
            return granted
        } catch {
            AppLog.notifications.error("Authorization failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func rescheduleAll(now: Date = .now) async {
        AppLog.notifications.info("Rescheduling all notifications")
        let pending = await center.pendingNotificationRequests()
        let dailyReminderIdentifiers = pending
            .map(\.identifier)
            .filter {
                $0 == Identifier.legacyDailyReminder || $0.hasPrefix(Identifier.dailyReminderPrefix)
            }
        center.removePendingNotificationRequests(
            withIdentifiers: dailyReminderIdentifiers + [Identifier.eventArrived]
        )

        guard storage.notificationsEnabled else {
            AppLog.notifications.debug("Skipped: notifications disabled in app")
            return
        }
        guard await authorizationStatus() == .authorized else {
            AppLog.notifications.debug("Skipped: notifications not authorized")
            return
        }
        guard let eventDate = storage.eventTargetDate else {
            AppLog.notifications.debug("Skipped: no event date")
            return
        }

        if CountdownCalculator.isEventPassed(eventDate: eventDate, now: now) {
            AppLog.notifications.debug("Skipped: event already passed")
            return
        }

        await scheduleDailyReminder(eventDate: eventDate, now: now)
        await scheduleEventArrived(eventDate: eventDate, now: now)
        AppLog.notifications.info("Notifications scheduled")
    }

    private func scheduleDailyReminder(eventDate: Date, now: Date) async {
        let reminders = DailyReminderPlanner.reminders(
            eventDate: eventDate,
            now: now,
            label: storage.eventLabel
        )

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminder.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.identifier,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private func scheduleEventArrived(eventDate: Date, now: Date) async {
        guard eventDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "push.eventArrived.title")
        content.body = NotificationTextBuilder.eventArrivedBody(
            label: storage.eventLabel,
            customMessage: storage.eventArrivedMessage
        )
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: eventDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifier.eventArrived,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}

enum NotificationTextBuilder {
    static func dailyContent(
        eventDate: Date,
        now: Date,
        label: String?
    ) -> (title: String, body: String) {
        let days = CountdownCalculator.totalCalendarDays(from: now, to: eventDate)
        let title = String(localized: "push.daily.title \(days)")
        let alarmPhrase = quotedLine(GroundhogAlarmPhrases.phrase(for: now))
        let trimmedLabel = label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let body = if let trimmedLabel {
            String(localized: "push.daily.body.labeled.withAlarm \(alarmPhrase) \(trimmedLabel)")
        } else {
            String(localized: "push.daily.body.withAlarm \(alarmPhrase)")
        }
        return (title, body)
    }

    private static func quotedLine(_ line: String) -> String {
        "\u{201C}\(line)\u{201D}"
    }

    static func eventArrivedBody(label: String?, customMessage: String?) -> String {
        let custom = customMessage?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        if let custom {
            if let label {
                return String(localized: "push.eventArrived.body.custom \(custom) \(label)")
            }
            return custom
        }
        if let label {
            return String(localized: "push.eventArrived.body \(label)")
        }
        return String(localized: "push.eventArrived.bodyGeneric")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
