import Foundation

enum GroundhogAlarmPhrases {
    static let localizationKeys = [
        "push.alarm.1",
        "push.alarm.2",
        "push.alarm.3",
        "push.alarm.4",
        "push.alarm.5",
        "push.alarm.6",
        "push.alarm.7",
    ]

    static func localizationKey(for date: Date, calendar: Calendar = .current) -> String {
        let startOfDay = calendar.startOfDay(for: date)
        let dayOrdinal = calendar.ordinality(of: .day, in: .era, for: startOfDay) ?? 0
        let index = dayOrdinal % localizationKeys.count
        return localizationKeys[index]
    }

    static func phrase(for date: Date, calendar: Calendar = .current) -> String {
        String(localized: String.LocalizationValue(localizationKey(for: date, calendar: calendar)))
    }
}
