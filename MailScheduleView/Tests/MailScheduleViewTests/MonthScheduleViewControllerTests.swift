import XCTest
@testable import MailScheduleView

final class MonthScheduleViewControllerTests: XCTestCase {

    // MARK: - dateRange

    func testDateRangeCoversFullMonth() {
        let date = makeDate(year: 2026, month: 3, day: 15)
        let vc = MonthScheduleViewController(date: date)

        let expectedStart = makeDate(year: 2026, month: 3, day: 1)
        let expectedEnd = makeDate(year: 2026, month: 3, day: 31, hour: 23, minute: 59)

        XCTAssertEqual(vc.dateRange.startDate, expectedStart)
        XCTAssertEqual(vc.dateRange.endDate, expectedEnd)
    }

    func testDateRangeForFebruary() {
        let date = makeDate(year: 2026, month: 2, day: 10)
        let vc = MonthScheduleViewController(date: date)

        let expectedStart = makeDate(year: 2026, month: 2, day: 1)
        let expectedEnd = makeDate(year: 2026, month: 2, day: 28, hour: 23, minute: 59)

        XCTAssertEqual(vc.dateRange.startDate, expectedStart)
        XCTAssertEqual(vc.dateRange.endDate, expectedEnd)
    }

    func testDateRangeForFirstDayOfMonth() {
        let date = makeDate(year: 2026, month: 4, day: 1)
        let vc = MonthScheduleViewController(date: date)

        let expectedStart = makeDate(year: 2026, month: 4, day: 1)
        let expectedEnd = makeDate(year: 2026, month: 4, day: 30, hour: 23, minute: 59)

        XCTAssertEqual(vc.dateRange.startDate, expectedStart)
        XCTAssertEqual(vc.dateRange.endDate, expectedEnd)
    }

    // MARK: - Placeholder view

    func testPlaceholderLabelExists() {
        let vc = MonthScheduleViewController(date: makeDate(day: 15))
        vc.loadViewIfNeeded()

        let label = vc.view.subviews.compactMap { $0 as? UILabel }.first
        XCTAssertNotNil(label)
        XCTAssertEqual(label?.text, "Month View")
    }

    // MARK: - showEvents (заглушка)

    func testShowEventsDoesNotCrash() {
        let vc = MonthScheduleViewController(date: makeDate(day: 15))
        vc.loadViewIfNeeded()

        let events = [
            CalendarEvent(startDate: makeDate(day: 15, hour: 9), endDate: makeDate(day: 15, hour: 10), title: "Test"),
        ]
        vc.showEvents(events: events)
        vc.showAllDayEvents(events: events)
        // Просто проверяем что не крашится
    }
}
