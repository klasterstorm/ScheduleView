import XCTest
@testable import MailScheduleView

final class WeekScheduleViewControllerTests: XCTestCase {

    // MARK: - dateRange

    func testDateRangeCoversSevenDays() {
        let monday = makeDate(year: 2026, month: 3, day: 23)
        let vc = WeekScheduleViewController(startOfWeek: monday)

        XCTAssertEqual(vc.dateRange.startDate, monday)

        let expectedEnd = makeDate(year: 2026, month: 3, day: 29, hour: 23, minute: 59)
        XCTAssertEqual(vc.dateRange.endDate, expectedEnd)
    }

    // MARK: - showEvents

    func testShowEventsPassesEventsToWeekView() {
        let monday = makeDate(day: 23)
        let vc = WeekScheduleViewController(startOfWeek: monday)
        vc.loadViewIfNeeded()

        let events = [
            ExampleCalendarEvent(startDate: makeDate(day: 23, hour: 9), endDate: makeDate(day: 23, hour: 10), title: "Понедельник"),
            ExampleCalendarEvent(startDate: makeDate(day: 25, hour: 14), endDate: makeDate(day: 25, hour: 15), title: "Среда"),
        ]
        vc.showEvents(events: events, viewForEvent: { _ in UIView() }, onEventTapped: nil)

        XCTAssertEqual(vc.weekView.events.count, 2)
    }

    // MARK: - ScrollView и WeekView в иерархии

    func testScrollViewContainsWeekView() {
        let vc = WeekScheduleViewController(startOfWeek: makeDate(day: 23))
        vc.loadViewIfNeeded()

        XCTAssertTrue(vc.view.subviews.contains(vc.scrollView))
        XCTAssertTrue(vc.scrollView.subviews.contains(vc.weekView))
    }

    // MARK: - Config проброс

    func testConfigIsForwardedToWeekView() {
        let vc = WeekScheduleViewController(startOfWeek: makeDate(day: 23))
        vc.config = ScheduleConfig(hourHeight: 80)

        XCTAssertEqual(vc.weekView.config.hourHeight, 80)
    }

    // MARK: - startOfWeek устанавливается

    func testStartOfWeekIsSetOnWeekView() {
        let monday = makeDate(day: 23)
        let vc = WeekScheduleViewController(startOfWeek: monday)

        XCTAssertEqual(vc.weekView.startOfWeek, monday)
    }
}
