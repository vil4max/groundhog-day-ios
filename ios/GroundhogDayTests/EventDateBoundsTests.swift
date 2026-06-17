import Foundation
@testable import GroundhogDay
import XCTest

final class EventDateBoundsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testLatestSelectableDateIsNinetyNineYearsAhead() {
        let reference = date(2026, 6, 17, 12, 0, 0)
        let latest = EventDateBounds.latestSelectableDate(from: reference, calendar: calendar)
        XCTAssertEqual(latest, date(2125, 6, 17, 23, 59, 59))
    }

    func testIsSelectableAcceptsFutureDateWithinRange() {
        let reference = date(2026, 6, 17, 12, 0, 0)
        let event = date(2072, 5, 22, 6, 0, 0)
        XCTAssertTrue(EventDateBounds.isSelectable(event, referenceDate: reference, calendar: calendar))
    }

    func testIsSelectableRejectsPastDate() {
        let reference = date(2026, 6, 17, 12, 0, 0)
        let event = date(2026, 6, 16, 12, 0, 0)
        XCTAssertFalse(EventDateBounds.isSelectable(event, referenceDate: reference, calendar: calendar))
    }

    func testIsSelectableRejectsDateBeyondNinetyNineYears() {
        let reference = date(2026, 6, 17, 12, 0, 0)
        let event = date(2126, 1, 1, 0, 0, 0)
        XCTAssertFalse(EventDateBounds.isSelectable(event, referenceDate: reference, calendar: calendar))
    }

    func testClampPinsPastDateToReference() {
        let reference = date(2026, 6, 17, 12, 0, 0)
        let past = date(2020, 1, 1, 0, 0, 0)
        XCTAssertEqual(EventDateBounds.clamp(past, referenceDate: reference, calendar: calendar), reference)
    }

    func testClampPinsFarFutureDateToLatestSelectable() {
        let reference = date(2026, 6, 17, 12, 0, 0)
        let farFuture = date(2200, 1, 1, 0, 0, 0)
        let latest = EventDateBounds.latestSelectableDate(from: reference, calendar: calendar)
        XCTAssertEqual(EventDateBounds.clamp(farFuture, referenceDate: reference, calendar: calendar), latest)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        _ second: Int
    ) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        ))!
    }
}
