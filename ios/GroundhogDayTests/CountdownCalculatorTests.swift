import Foundation
@testable import GroundhogDay
import XCTest

final class CountdownCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testValueInUnitForLongInterval() {
        let start = date(2026, 6, 17, 12, 0, 0)
        let end = date(2072, 5, 22, 6, 0, 0)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.years, from: start, to: end, calendar: calendar), 45)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.months, from: start, to: end, calendar: calendar), 551)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.days, from: start, to: end, calendar: calendar), 16776)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.weeks, from: start, to: end, calendar: calendar), 16776 / 7)
    }

    func testValueInUnitForShortInterval() {
        let start = date(2026, 1, 1, 10, 0, 0)
        let end = date(2026, 1, 15, 14, 30, 45)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.years, from: start, to: end, calendar: calendar), 0)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.months, from: start, to: end, calendar: calendar), 0)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.weeks, from: start, to: end, calendar: calendar), 2)
        XCTAssertEqual(CountdownCalculator.valueInUnit(.days, from: start, to: end, calendar: calendar), 14)
    }

    func testComponentsBreakdown() {
        let start = date(2026, 1, 1, 10, 0, 0)
        let end = date(2026, 1, 15, 14, 30, 45)
        let components = CountdownCalculator.components(from: start, to: end, calendar: calendar)
        XCTAssertEqual(components.years, 0)
        XCTAssertEqual(components.months, 0)
        XCTAssertEqual(components.weeks, 2)
        XCTAssertEqual(components.days, 0)
        XCTAssertEqual(components.hours, 4)
        XCTAssertEqual(components.minutes, 30)
        XCTAssertEqual(components.seconds, 45)
    }

    func testComponentsUseEachUnitRange() {
        let start = date(2026, 3, 1, 23, 0, 0)
        let end = date(2026, 3, 3, 1, 0, 0)
        let components = CountdownCalculator.components(from: start, to: end, calendar: calendar)
        XCTAssertEqual(components.years, 0)
        XCTAssertEqual(components.months, 0)
        XCTAssertEqual(components.weeks, 0)
        XCTAssertEqual(components.days, 1)
        XCTAssertEqual(components.hours, 2)
        XCTAssertEqual(components.minutes, 0)
        XCTAssertEqual(components.seconds, 0)
    }

    func testComponentsAcrossLeapYearMonth() {
        let start = date(2024, 1, 31, 12, 0, 0)
        let end = date(2024, 3, 1, 12, 0, 0)
        let components = CountdownCalculator.components(from: start, to: end, calendar: calendar)
        XCTAssertEqual(components.years, 0)
        XCTAssertEqual(components.months, 1)
        XCTAssertEqual(components.weeks, 0)
        XCTAssertEqual(components.days, 1)
        XCTAssertEqual(components.hours, 0)
        XCTAssertEqual(components.minutes, 0)
        XCTAssertEqual(components.seconds, 0)
    }

    func testComponentsRecomposeToEndDate() {
        let start = date(2026, 6, 17, 12, 0, 0)
        let end = date(2072, 5, 15, 6, 0, 0)
        let components = CountdownCalculator.components(from: start, to: end, calendar: calendar)
        let recomposed = recompose(components, from: start, calendar: calendar)
        XCTAssertEqual(recomposed, end)
    }

    func testTotalCalendarDays() {
        let start = date(2026, 1, 1, 23, 0, 0)
        let end = date(2026, 1, 10, 1, 0, 0)
        let days = CountdownCalculator.totalCalendarDays(from: start, to: end, calendar: calendar)
        XCTAssertEqual(days, 9)
    }

    func testIsEventPassed() {
        let past = date(2020, 1, 1, 9, 0, 0)
        let now = date(2026, 6, 1, 12, 0, 0)
        XCTAssertTrue(CountdownCalculator.isEventPassed(eventDate: past, now: now))
        XCTAssertFalse(CountdownCalculator.isEventPassed(eventDate: now.addingTimeInterval(3600), now: now))
    }

    func testPastEventReturnsZeroComponents() {
        let start = date(2026, 6, 1, 12, 0, 0)
        let end = date(2026, 1, 1, 9, 0, 0)
        let components = CountdownCalculator.components(from: start, to: end, calendar: calendar)
        XCTAssertEqual(components, .zero)
    }

    func testIsWithin24Hours() {
        let now = date(2026, 6, 1, 12, 0, 0)
        let in12Hours = now.addingTimeInterval(12 * 3600)
        let in25Hours = now.addingTimeInterval(25 * 3600)
        XCTAssertTrue(CountdownCalculator.isWithin24Hours(eventDate: in12Hours, now: now))
        XCTAssertFalse(CountdownCalculator.isWithin24Hours(eventDate: in25Hours, now: now))
        XCTAssertFalse(CountdownCalculator.isWithin24Hours(eventDate: now, now: now))
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

    private func recompose(_ components: CountdownComponents, from start: Date, calendar: Calendar) -> Date {
        var date = start
        date = calendar.date(byAdding: .year, value: components.years, to: date)!
        date = calendar.date(byAdding: .month, value: components.months, to: date)!
        date = calendar.date(byAdding: .day, value: components.weeks * 7 + components.days, to: date)!
        date = calendar.date(byAdding: .hour, value: components.hours, to: date)!
        date = calendar.date(byAdding: .minute, value: components.minutes, to: date)!
        date = calendar.date(byAdding: .second, value: components.seconds, to: date)!
        return date
    }
}
