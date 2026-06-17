import Foundation

struct CountdownComponents: Equatable, Sendable {
    var years: Int
    var months: Int
    var weeks: Int
    var days: Int
    var hours: Int
    var minutes: Int
    var seconds: Int

    static let zero = CountdownComponents(
        years: 0,
        months: 0,
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0
    )

    var orderedValues: [Int] {
        [years, months, weeks, days, hours, minutes, seconds]
    }
}

enum CountdownUnit: Int, CaseIterable, Sendable {
    case years
    case months
    case weeks
    case days
    case hours
    case minutes
    case seconds

    var localizationKey: String {
        switch self {
        case .years: "unit.years"
        case .months: "unit.months"
        case .weeks: "unit.weeks"
        case .days: "unit.days"
        case .hours: "unit.hours"
        case .minutes: "unit.minutes"
        case .seconds: "unit.seconds"
        }
    }

    var shortLocalizationKey: String {
        switch self {
        case .years: "unit.years.short"
        case .months: "unit.months.short"
        case .weeks: "unit.weeks.short"
        case .days: "unit.days.short"
        case .hours: "unit.hours.short"
        case .minutes: "unit.minutes.short"
        case .seconds: "unit.seconds.short"
        }
    }
}

struct EventSnapshot: Codable, Equatable, Sendable {
    var eventTargetDate: Date?
    var eventLabel: String?
    var notificationsEnabled: Bool
    var dailyReminderMessage: String?
    var eventArrivedMessage: String?
    var defaultCountdownUnitRawValue: Int?
    var lastModifiedAt: TimeInterval
}
