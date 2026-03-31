import XCTest
@testable import MailScheduleView

final class DayScheduleViewControllerTests: XCTestCase {

    // MARK: - dateRange

    func testDateRangeCoversOneDay() {
        let date = makeDate(year: 2026, month: 3, day: 25, hour: 14, minute: 30)
        let vc = DayScheduleViewController(date: date)

        let startOfDay = makeDate(year: 2026, month: 3, day: 25, hour: 0, minute: 0)
        let endOfDay = makeDate(year: 2026, month: 3, day: 25, hour: 23, minute: 59)

        XCTAssertEqual(vc.dateRange.startDate, startOfDay)
        XCTAssertEqual(vc.dateRange.endDate, endOfDay)
    }

    // MARK: - showEvents

    func testShowEventsPassesEventsToDayView() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.loadViewIfNeeded()

        let events: [IScheduleEvent] = [
            ExampleCalendarEvent(startDate: makeDate(day: 25, hour: 9), endDate: makeDate(day: 25, hour: 10), title: "Встреча"),
            ExampleCalendarEvent(startDate: makeDate(day: 25, hour: 14), endDate: makeDate(day: 25, hour: 15), title: "Обед"),
        ]
        vc.showEvents(events: events, viewForEvent: { _ in UIView() }, onEventTapped: nil)

        XCTAssertEqual(vc.dayView.events.count, 2)
    }

    // MARK: - viewForEvent вызывается через showEvents

    func testViewForEventIsCalledFromShowEvents() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.loadViewIfNeeded()

        var callCount = 0
        vc.showEvents(
            events: [ExampleCalendarEvent(startDate: makeDate(day: 25, hour: 9), endDate: makeDate(day: 25, hour: 10), title: "Test")],
            viewForEvent: { _ in
                callCount += 1
                return UIView()
            },
            onEventTapped: nil
        )

        XCTAssertEqual(callCount, 1)
    }

    // MARK: - onEventTapped пробрасывается через showEvents

    func testOnEventTappedIsSetFromShowEvents() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.loadViewIfNeeded()

        vc.showEvents(
            events: [ExampleCalendarEvent(startDate: makeDate(day: 25, hour: 9), endDate: makeDate(day: 25, hour: 10), title: "Test")],
            viewForEvent: { _ in UIView() },
            onEventTapped: { _ in }
        )

        XCTAssertNotNil(vc.dayView.onEventTapped)
    }

    // MARK: - ScrollView и DayView в иерархии

    func testScrollViewContainsDayView() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.loadViewIfNeeded()

        XCTAssertTrue(vc.view.subviews.contains(vc.scrollView))
        XCTAssertTrue(vc.scrollView.subviews.contains(vc.dayView))
    }

    // MARK: - Config проброс

    func testConfigIsForwardedToDayView() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.config = ScheduleConfig(hourHeight: 80, minEventHeight: 30)

        XCTAssertEqual(vc.dayView.config.hourHeight, 80)
        XCTAssertEqual(vc.dayView.config.minEventHeight, 30)
    }

    func testTimelineConfigIsForwardedToDayView() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.timelineConfig = TimelineConfig(timeColumnWidth: 70)

        XCTAssertEqual(vc.dayView.timelineConfig.timeColumnWidth, 70)
    }
}
