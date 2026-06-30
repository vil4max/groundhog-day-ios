import Foundation
@testable import GroundhogDay
import XCTest

final class GroundhogAlarmPhrasesTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testPhraseKeyRotatesByCalendarDay() {
        let dayOne = date(2026, 6, 30, 6, 0, 0)
        let dayTwo = date(2026, 7, 1, 6, 0, 0)

        let keyOne = GroundhogAlarmPhrases.localizationKey(for: dayOne, calendar: calendar)
        let keyTwo = GroundhogAlarmPhrases.localizationKey(for: dayTwo, calendar: calendar)

        XCTAssertTrue(GroundhogAlarmPhrases.localizationKeys.contains(keyOne))
        XCTAssertTrue(GroundhogAlarmPhrases.localizationKeys.contains(keyTwo))
        XCTAssertNotEqual(keyOne, keyTwo)
    }

    func testDailyNotificationBodyBeginsWithQuotedAlarmPhrase() {
        let eventDate = date(2072, 5, 22, 6, 0, 0)
        let now = date(2026, 6, 30, 6, 0, 0)

        let content = NotificationTextBuilder.dailyContent(
            eventDate: eventDate,
            now: now,
            label: nil
        )

        let alarmPhrase = GroundhogAlarmPhrases.phrase(for: now, calendar: calendar)
        XCTAssertTrue(content.body.hasPrefix("\u{201C}\(alarmPhrase)\u{201D}"))
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
