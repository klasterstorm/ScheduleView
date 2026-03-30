import XCTest
@testable import MailScheduleView

// MARK: - Мок делегата

private final class MockDelegate: ICalendarSchedulePageControllerDelegate {
    var requestedSchedules: [IScheduleViewController] = []

    func eventsRequested(for schedule: IScheduleViewController) {
        requestedSchedules.append(schedule)
    }
}

final class CalendarSchedulePageViewTests: XCTestCase {

    // MARK: - UIPageViewController как subview

    func testPageViewControllerViewIsSubview() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))

        XCTAssertTrue(pageView.subviews.contains(pageView.pageViewController.view))
    }

    // MARK: - scroll(to:) — day mode

    func testScrollToDayUpdatesCurrentDate() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        let targetDate = makeDate(day: 28)

        pageView.scroll(to: targetDate)

        let startOfTarget = Calendar.current.startOfDay(for: targetDate)
        XCTAssertEqual(pageView.currentDate, targetDate)

        let currentVC = pageView.pageViewController.viewControllers?.first as? DayScheduleViewController
        XCTAssertNotNil(currentVC)
        XCTAssertEqual(currentVC?.dateRange.startDate, startOfTarget)
    }

    // MARK: - scroll(to:) вызывает eventsRequested

    func testScrollCallsEventsRequested() {
        let mockDelegate = MockDelegate()
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.delegate = mockDelegate

        pageView.scroll(to: makeDate(day: 28))

        XCTAssertEqual(mockDelegate.requestedSchedules.count, 1)
    }

    // MARK: - displayMode переключает тип VC

    func testDayModeCreatesDayVC() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .day

        let currentVC = pageView.pageViewController.viewControllers?.first
        XCTAssertTrue(currentVC is DayScheduleViewController)
    }

    func testWeekModeCreatesWeekVC() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .week

        let currentVC = pageView.pageViewController.viewControllers?.first
        XCTAssertTrue(currentVC is WeekScheduleViewController)
    }

    func testMonthModeCreatesMonthVC() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .month

        let currentVC = pageView.pageViewController.viewControllers?.first
        XCTAssertTrue(currentVC is MonthScheduleViewController)
    }

    // MARK: - Фабрика: навигация по датам

    func testNextDateForDayMode() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .day

        let next = pageView.nextDate(after: makeDate(day: 25))
        XCTAssertEqual(Calendar.current.component(.day, from: next), 26)
    }

    func testPreviousDateForDayMode() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .day

        let prev = pageView.previousDate(before: makeDate(day: 25))
        XCTAssertEqual(Calendar.current.component(.day, from: prev), 24)
    }

    func testNextDateForWeekMode() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .week

        let next = pageView.nextDate(after: makeDate(day: 23))
        XCTAssertEqual(Calendar.current.component(.day, from: next), 30)
    }

    func testNextDateForMonthMode() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .month

        let next = pageView.nextDate(after: makeDate(month: 3, day: 1))
        XCTAssertEqual(Calendar.current.component(.month, from: next), 4)
    }

    // MARK: - DataSource создаёт VC для соседних страниц

    func testDataSourceCreatesVCBefore() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .day

        guard let currentVC = pageView.pageViewController.viewControllers?.first else {
            XCTFail("Нет текущего VC")
            return
        }

        let prevVC = pageView.pageViewController(
            pageView.pageViewController,
            viewControllerBefore: currentVC
        )
        XCTAssertNotNil(prevVC)
        XCTAssertTrue(prevVC is DayScheduleViewController)

        let prevDay = (prevVC as! DayScheduleViewController).dateRange.startDate
        XCTAssertEqual(Calendar.current.component(.day, from: prevDay), 24)
    }

    func testDataSourceCreatesVCAfter() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.displayMode = .day

        guard let currentVC = pageView.pageViewController.viewControllers?.first else {
            XCTFail("Нет текущего VC")
            return
        }

        let nextVC = pageView.pageViewController(
            pageView.pageViewController,
            viewControllerAfter: currentVC
        )
        XCTAssertNotNil(nextVC)
        XCTAssertTrue(nextVC is DayScheduleViewController)

        let nextDay = (nextVC as! DayScheduleViewController).dateRange.startDate
        XCTAssertEqual(Calendar.current.component(.day, from: nextDay), 26)
    }

    // MARK: - DataSource вызывает eventsRequested для соседних страниц

    func testDataSourceCallsEventsRequestedForAdjacentPages() {
        let mockDelegate = MockDelegate()
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.delegate = mockDelegate

        guard let currentVC = pageView.pageViewController.viewControllers?.first else {
            XCTFail("Нет текущего VC")
            return
        }

        _ = pageView.pageViewController(pageView.pageViewController, viewControllerBefore: currentVC)
        _ = pageView.pageViewController(pageView.pageViewController, viewControllerAfter: currentVC)

        XCTAssertEqual(mockDelegate.requestedSchedules.count, 2)
    }

    // MARK: - Config пробрасывается в создаваемые VC

    // MARK: - onDateChanged

    func testOnDateChangedCalledOnScroll() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        var receivedDates: [Date] = []
        pageView.onDateChanged = { date in
            receivedDates.append(date)
        }

        pageView.scroll(to: makeDate(day: 28))

        XCTAssertEqual(receivedDates.count, 1)
        XCTAssertEqual(Calendar.current.component(.day, from: receivedDates[0]), 28)
    }

    // MARK: - Config пробрасывается в создаваемые VC

    func testConfigIsForwardedToCreatedDayVC() {
        let pageView = CalendarSchedulePageView(initialDate: makeDate(day: 25))
        pageView.config = ScheduleConfig(hourHeight: 80)
        pageView.timelineConfig = TimelineConfig(timeColumnWidth: 70)

        pageView.scroll(to: makeDate(day: 26))

        let currentVC = pageView.pageViewController.viewControllers?.first as? DayScheduleViewController
        XCTAssertEqual(currentVC?.config.hourHeight, 80)
        XCTAssertEqual(currentVC?.timelineConfig.timeColumnWidth, 70)
    }
}
