import Foundation

enum CountdownCalculator {
    static func valueInUnit(
        _ unit: CountdownUnit,
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> Int {
        guard end > start else {
            return 0
        }

        let totalDays = totalCalendarDays(from: start, to: end, calendar: calendar)
        let totalSeconds = Int(end.timeIntervalSince(start))

        switch unit {
        case .years:
            return calendar.dateComponents([.year], from: start, to: end).year ?? 0
        case .months:
            let parts = calendar.dateComponents([.year, .month], from: start, to: end)
            return (parts.year ?? 0) * 12 + (parts.month ?? 0)
        case .weeks:
            return totalDays / 7
        case .days:
            return totalDays
        case .hours:
            return totalSeconds / 3600
        case .minutes:
            return totalSeconds / 60
        case .seconds:
            return totalSeconds
        }
    }

    static func unitValues(
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> [Int] {
        CountdownUnit.allCases.map { valueInUnit($0, from: start, to: end, calendar: calendar) }
    }

    static func components(
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> CountdownComponents {
        guard end > start else {
            return .zero
        }

        var cursor = IntervalCursor(start: start, end: end, calendar: calendar)
        let years = cursor.takeFullYears()
        let months = cursor.takeFullMonths()
        let (weeks, days) = cursor.takeWeeksAndDays()
        let (hours, minutes, seconds) = cursor.takeTimeOfDay()

        return CountdownComponents(
            years: years,
            months: months,
            weeks: weeks,
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds
        )
    }

    static func totalCalendarDays(
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return max(0, calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0)
    }

    static func isEventPassed(eventDate: Date, now: Date = .now) -> Bool {
        eventDate <= now
    }

    static func isWithin24Hours(eventDate: Date, now: Date = .now) -> Bool {
        let interval = eventDate.timeIntervalSince(now)
        return interval > 0 && interval <= 24 * 60 * 60
    }
}

private struct IntervalCursor {
    private var remainingStart: Date
    private let end: Date
    private let calendar: Calendar

    init(start: Date, end: Date, calendar: Calendar) {
        remainingStart = start
        self.end = end
        self.calendar = calendar
    }

    mutating func takeFullYears() -> Int {
        takeLargest(.year)
    }

    mutating func takeFullMonths() -> Int {
        takeLargest(.month)
    }

    mutating func takeWeeksAndDays() -> (weeks: Int, days: Int) {
        let totalDays = takeLargest(.day)
        return (totalDays / 7, totalDays % 7)
    }

    mutating func takeTimeOfDay() -> (hours: Int, minutes: Int, seconds: Int) {
        let components = calendar.dateComponents([.hour, .minute, .second], from: remainingStart, to: end)
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        let seconds = max(0, components.second ?? 0)

        if let advanced = calendar.date(byAdding: DateComponents(hour: hours, minute: minutes, second: seconds), to: remainingStart) {
            remainingStart = advanced
        }

        return (hours, minutes, seconds)
    }

    private mutating func takeLargest(_ component: Calendar.Component) -> Int {
        let difference = calendar.dateComponents([component], from: remainingStart, to: end)
        let value = max(0, componentValue(in: difference, component: component))
        if value > 0, let advanced = calendar.date(byAdding: component, value: value, to: remainingStart) {
            remainingStart = advanced
        }
        return value
    }

    private func componentValue(in components: DateComponents, component: Calendar.Component) -> Int {
        switch component {
        case .year: components.year ?? 0
        case .month: components.month ?? 0
        case .day: components.day ?? 0
        default: 0
        }
    }
}
