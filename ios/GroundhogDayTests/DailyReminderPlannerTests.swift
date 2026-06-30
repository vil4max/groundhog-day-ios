import Foundation
@testable import GroundhogDay
import XCTest

final class DailyReminderPlannerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testMorningReminderUsesFireDateNotScheduleDate() {
        let eventDate = date(2072, 5, 22, 6, 0, 0)
        let scheduledMondayEvening = date(2026, 6, 29, 20, 0, 0)

        let reminders = DailyReminderPlanner.reminders(
            eventDate: eventDate,
            now: scheduledMondayEvening,
            label: nil,
            calendar: calendar
        )

        XCTAssertFalse(reminders.isEmpty)
        let firstReminder = reminders[0]
        XCTAssertEqual(firstReminder.fireDate, date(2026, 6, 30, 6, 0, 0))

        let daysAtScheduleTime = CountdownCalculator.totalCalendarDays(
            from: scheduledMondayEvening,
            to: eventDate,
            calendar: calendar
        )
        let daysOnFireMorning = CountdownCalculator.totalCalendarDays(
            from: firstReminder.fireDate,
            to: eventDate,
            calendar: calendar
        )
        XCTAssertEqual(daysAtScheduleTime - 1, daysOnFireMorning)
        XCTAssertEqual(firstReminder.days, daysOnFireMorning)
    }

    func testEachReminderDayCountDecreasesByOne() {
        let eventDate = date(2072, 5, 22, 6, 0, 0)
        let now = date(2026, 6, 29, 20, 0, 0)

        let reminders = DailyReminderPlanner.reminders(
            eventDate: eventDate,
            now: now,
            label: nil,
            calendar: calendar
        )

        XCTAssertGreaterThan(reminders.count, 1)
        for index in 1 ..< reminders.count {
            XCTAssertEqual(reminders[index].days, reminders[index - 1].days - 1)
        }
    }

    func testNextMorningReminderDateBeforeSixAMUsesToday() {
        let now = date(2026, 6, 30, 5, 30, 0)
        let nextFire = DailyReminderPlanner.nextMorningReminderDate(after: now, calendar: calendar)
        XCTAssertEqual(nextFire, date(2026, 6, 30, 6, 0, 0))
    }

    func testNextMorningReminderDateAfterSixAMUsesTomorrow() {
        let now = date(2026, 6, 30, 7, 0, 0)
        let nextFire = DailyReminderPlanner.nextMorningReminderDate(after: now, calendar: calendar)
        XCTAssertEqual(nextFire, date(2026, 7, 1, 6, 0, 0))
    }

    func testReminderCountIsLimitedToMaxScheduledCount() {
        let eventDate = date(2126, 1, 1, 6, 0, 0)
        let now = date(2026, 1, 1, 12, 0, 0)

        let reminders = DailyReminderPlanner.reminders(
            eventDate: eventDate,
            now: now,
            label: nil,
            calendar: calendar
        )

        XCTAssertEqual(reminders.count, DailyReminderPlanner.maxScheduledCount)
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
