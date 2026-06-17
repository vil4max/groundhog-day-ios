import Foundation

enum EventDateBounds {
    static let maxYearsAhead = 99

    static func latestSelectableDate(
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        guard let capped = calendar.date(byAdding: .year, value: maxYearsAhead, to: referenceDate) else {
            return referenceDate
        }
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: capped) ?? capped
    }

    static func clamp(
        _ date: Date,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        min(max(date, referenceDate), latestSelectableDate(from: referenceDate, calendar: calendar))
    }

    static func isSelectable(
        _ date: Date,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        date > referenceDate && date <= latestSelectableDate(from: referenceDate, calendar: calendar)
    }
}
