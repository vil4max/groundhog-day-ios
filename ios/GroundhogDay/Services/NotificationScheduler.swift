import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {
    enum Identifier {
        static let dailyReminder = "daily-reminder"
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
        center.removePendingNotificationRequests(withIdentifiers: [
            Identifier.dailyReminder,
            Identifier.eventArrived,
        ])

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
        let content = UNMutableNotificationContent()
        let daily = NotificationTextBuilder.dailyContent(
            eventDate: eventDate,
            now: now,
            label: storage.eventLabel,
            customGreeting: storage.dailyReminderMessage
        )
        content.title = daily.title
        content.body = daily.body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 6
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.dailyReminder,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
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
        label: String?,
        customGreeting: String?
    ) -> (title: String, body: String) {
        let title = String(localized: "push.daily.title")
        let greeting = customGreeting?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? String(localized: "push.daily.greeting")
        let countdown = dailyCountdownSummary(eventDate: eventDate, now: now, label: label)
        let body = String(localized: "push.daily.body \(greeting) \(countdown)")
        return (title, body)
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

    private static func dailyCountdownSummary(eventDate: Date, now: Date, label: String?) -> String {
        let components = CountdownCalculator.components(from: now, to: eventDate)
        let summary = topComponentsSummary(components)
        let days = CountdownCalculator.totalCalendarDays(from: now, to: eventDate)
        let daysPart = String(localized: "push.orDays \(days)")
        let countdown = String(localized: "push.daily.countdown \(summary) \(daysPart)")
        if let label {
            return String(localized: "countdown.until \(label)") + ". " + countdown
        }
        return countdown
    }

    private static func topComponentsSummary(_ components: CountdownComponents) -> String {
        let pairs: [(Int, String)] = [
            (components.years, String(localized: "unit.years")),
            (components.months, String(localized: "unit.months")),
            (components.weeks, String(localized: "unit.weeks")),
            (components.days, String(localized: "unit.days")),
            (components.hours, String(localized: "unit.hours")),
            (components.minutes, String(localized: "unit.minutes")),
            (components.seconds, String(localized: "unit.seconds")),
        ]
        let nonZero = pairs.filter { $0.0 > 0 }.prefix(3)
        return nonZero.map { "\($0.0) \($0.1)" }.joined(separator: ", ")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
