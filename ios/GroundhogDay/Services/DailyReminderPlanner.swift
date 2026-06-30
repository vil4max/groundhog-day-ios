import Foundation

enum DailyReminderPlanner {
    static let maxScheduledCount = 64
    static let identifierPrefix = "daily-reminder-"
    static let legacyIdentifier = "daily-reminder"

    struct ScheduledReminder: Equatable {
        let identifier: String
        let fireDate: Date
        let days: Int
        let title: String
        let body: String
    }

    static func reminders(
        eventDate: Date,
        now: Date,
        label: String?,
        calendar: Calendar = .current
    ) -> [ScheduledReminder] {
        var result: [ScheduledReminder] = []
        var fireDate = nextMorningReminderDate(after: now, calendar: calendar)

        for index in 0 ..< maxScheduledCount {
            guard fireDate < eventDate else { break }

            let days = CountdownCalculator.totalCalendarDays(from: fireDate, to: eventDate, calendar: calendar)
            guard days > 0 else { break }

            let daily = NotificationTextBuilder.dailyContent(
                eventDate: eventDate,
                now: fireDate,
                label: label
            )

            result.append(
                ScheduledReminder(
                    identifier: "\(identifierPrefix)\(index)",
                    fireDate: fireDate,
                    days: days,
                    title: daily.title,
                    body: daily.body
                )
            )

            guard let nextFireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) else { break }
            fireDate = nextFireDate
        }

        return result
    }

    static func nextMorningReminderDate(after now: Date, calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 6
        components.minute = 0
        components.second = 0

        let todayAtSix = calendar.date(from: components) ?? now
        if now < todayAtSix {
            return todayAtSix
        }

        return calendar.date(byAdding: .day, value: 1, to: todayAtSix) ?? todayAtSix
    }
}
