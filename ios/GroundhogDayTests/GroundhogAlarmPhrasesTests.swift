import Foundation
@testable import GroundhogDay
import XCTest

final class GroundhogAlarmPhrasesTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testDailyNotificationUsesFixedAlarmTitleAndDaysBody() {
        let eventDate = date(2072, 5, 22, 6, 0, 0)
        let now = date(2026, 6, 30, 6, 0, 0)

        let content = NotificationTextBuilder.dailyContent(
            eventDate: eventDate,
            now: now,
            label: nil
        )

        XCTAssertEqual(content.title, GroundhogAlarmPhrases.title)
        XCTAssertEqual(
            content.body,
            String(localized: "push.daily.body \(CountdownCalculator.totalCalendarDays(from: now, to: eventDate, calendar: calendar))")
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Date {
        calendar.date(from: DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        ))!
    }
}
