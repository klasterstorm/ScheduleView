import XCTest
@testable import MailScheduleView

final class CurrentTimeIndicatorTests: XCTestCase {

    // MARK: - CurrentTimeIndicatorConfig дефолты

    func testConfigDefaults() {
        let config = CurrentTimeIndicatorConfig()

        XCTAssertEqual(config.color, .systemRed)
        XCTAssertEqual(config.lineHeight, 1.0)
        XCTAssertEqual(config.circleRadius, 5.0)
        XCTAssertFalse(config.isHidden)
    }

    // MARK: - ScheduleConfig содержит currentTimeIndicator

    func testScheduleConfigContainsIndicatorConfig() {
        let config = ScheduleConfig()
        XCTAssertFalse(config.currentTimeIndicator.isHidden)
        XCTAssertEqual(config.currentTimeIndicator.color, .systemRed)
    }

    func testScheduleConfigCustomIndicator() {
        let indicator = CurrentTimeIndicatorConfig(color: .blue, isHidden: true)
        let config = ScheduleConfig(currentTimeIndicator: indicator)

        XCTAssertEqual(config.currentTimeIndicator.color, .blue)
        XCTAssertTrue(config.currentTimeIndicator.isHidden)
    }

    // MARK: - DayScheduleView: индикатор виден в standalone

    func testDayViewIndicatorVisibleInStandalone() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.displayMode = .standalone
        view.setCurrentTime(minutesSinceMidnight: 720) // 12:00
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first
        XCTAssertNotNil(indicator)
        XCTAssertFalse(indicator!.isHidden)
    }

    // MARK: - DayScheduleView: индикатор скрыт в embedded

    func testDayViewIndicatorHiddenInEmbedded() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.displayMode = .embedded
        view.setCurrentTime(minutesSinceMidnight: 720)
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first
        XCTAssertNotNil(indicator)
        XCTAssertTrue(indicator!.isHidden)
    }

    // MARK: - DayScheduleView: индикатор скрыт при isHidden = true

    func testDayViewIndicatorHiddenWhenConfigIsHidden() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.config = ScheduleConfig(currentTimeIndicator: CurrentTimeIndicatorConfig(isHidden: true))
        view.setCurrentTime(minutesSinceMidnight: 720)
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first
        XCTAssertTrue(indicator!.isHidden)
    }

    // MARK: - DayScheduleView: позиция индикатора

    func testDayViewIndicatorYPosition() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.config = ScheduleConfig(hourHeight: 60)
        view.setCurrentTime(minutesSinceMidnight: 600) // 10:00
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first!
        // y = 600 * 1.0 = 600, индикатор центрирован на этой линии
        let expectedY: CGFloat = 600
        XCTAssertEqual(indicator.center.y, expectedY, accuracy: 6) // допуск на circleRadius
    }

    // MARK: - DayScheduleView: setCurrentTime обновляет позицию

    func testDayViewSetCurrentTimeUpdatesPosition() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.config = ScheduleConfig(hourHeight: 60)

        view.setCurrentTime(minutesSinceMidnight: 300) // 05:00
        view.layoutIfNeeded()
        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first!
        let firstY = indicator.center.y

        view.setCurrentTime(minutesSinceMidnight: 900) // 15:00
        view.layoutIfNeeded()
        let secondY = indicator.center.y

        XCTAssertNotEqual(firstY, secondY)
        XCTAssertEqual(secondY, 900, accuracy: 6)
    }

    // MARK: - WeekScheduleView: индикатор виден

    func testWeekViewIndicatorVisible() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.setCurrentTime(minutesSinceMidnight: 720)
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first
        XCTAssertNotNil(indicator)
        XCTAssertFalse(indicator!.isHidden)
    }

    // MARK: - WeekScheduleView: индикатор скрыт при isHidden

    func testWeekViewIndicatorHiddenWhenConfigIsHidden() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.config = ScheduleConfig(currentTimeIndicator: CurrentTimeIndicatorConfig(isHidden: true))
        view.events = []
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first
        XCTAssertTrue(indicator!.isHidden)
    }

    // MARK: - WeekScheduleView: позиция индикатора

    func testWeekViewIndicatorYPosition() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.config = ScheduleConfig(hourHeight: 60)
        view.setCurrentTime(minutesSinceMidnight: 600) // 10:00
        view.layoutIfNeeded()

        let indicator = view.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first!
        let expectedY: CGFloat = 600
        XCTAssertEqual(indicator.center.y, expectedY, accuracy: 6)
    }

    // MARK: - DayScheduleViewController: таймер

    func testDayVCStartsTimerOnAppear() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.currentDateProvider = { makeDate(day: 25, hour: 14, minute: 30) }
        vc.loadViewIfNeeded()

        vc.viewWillAppear(false)

        // Индикатор должен быть обновлён (14:30 = 870 минут)
        let indicator = vc.dayView.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first!
        vc.dayView.layoutIfNeeded()
        XCTAssertFalse(indicator.isHidden)
    }

    func testDayVCStopsTimerOnDisappear() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.loadViewIfNeeded()

        vc.viewWillAppear(false)
        vc.viewWillDisappear(false)

        // Таймер остановлен — просто проверяем, что не крашит
    }

    // MARK: - DayScheduleViewController: автоскролл

    func testDayVCScrollsToCurrentTimeOnFirstLayout() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.currentDateProvider = { makeDate(day: 25, hour: 14, minute: 0) }
        vc.loadViewIfNeeded()

        vc.view.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        vc.scrollView.contentSize = CGSize(width: 320, height: vc.config.timelineHeight)
        vc.view.layoutIfNeeded()
        vc.viewDidLayoutSubviews()

        // contentOffset.y должен быть примерно (14*60 - 300) = 540
        let expectedY = 14.0 * 60.0 - 300.0
        XCTAssertEqual(vc.scrollView.contentOffset.y, expectedY, accuracy: 10)
    }

    func testDayVCUsesInitialScrollOffset() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        vc.initialScrollOffsetY = 200
        vc.loadViewIfNeeded()

        vc.view.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        vc.view.layoutIfNeeded()
        vc.viewDidLayoutSubviews()

        XCTAssertEqual(vc.scrollView.contentOffset.y, 200, accuracy: 1)
    }

    // MARK: - DayScheduleViewController: currentDateProvider используется

    func testDayVCUsesCurrentDateProvider() {
        let vc = DayScheduleViewController(date: makeDate(day: 25))
        // 10:00 = 600 минут
        vc.currentDateProvider = { makeDate(day: 25, hour: 10, minute: 0) }
        vc.loadViewIfNeeded()

        vc.viewWillAppear(false)
        vc.dayView.layoutIfNeeded()

        let indicator = vc.dayView.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first!
        let expectedY: CGFloat = 600
        XCTAssertEqual(indicator.center.y, expectedY, accuracy: 6)
    }

    // MARK: - WeekScheduleViewController: таймер

    func testWeekVCStartsTimerOnAppear() {
        let vc = WeekScheduleViewController(startOfWeek: makeDate(day: 23))
        vc.currentDateProvider = { makeDate(day: 25, hour: 14, minute: 30) }
        vc.loadViewIfNeeded()

        vc.viewWillAppear(false)

        let indicator = vc.weekView.subviews.compactMap { $0 as? CurrentTimeIndicatorView }.first!
        vc.weekView.layoutIfNeeded()
        XCTAssertFalse(indicator.isHidden)
    }

    // MARK: - WeekScheduleViewController: автоскролл

    func testWeekVCScrollsToCurrentTimeOnFirstLayout() {
        let vc = WeekScheduleViewController(startOfWeek: makeDate(day: 23))
        vc.currentDateProvider = { makeDate(day: 25, hour: 14, minute: 0) }
        vc.loadViewIfNeeded()

        vc.view.frame = CGRect(x: 0, y: 0, width: 700, height: 600)
        vc.scrollView.contentSize = CGSize(width: 700, height: vc.config.timelineHeight)
        vc.view.layoutIfNeeded()
        vc.viewDidLayoutSubviews()

        let expectedY = 14.0 * 60.0 - 300.0
        XCTAssertEqual(vc.scrollView.contentOffset.y, expectedY, accuracy: 10)
    }

    func testWeekVCUsesInitialScrollOffset() {
        let vc = WeekScheduleViewController(startOfWeek: makeDate(day: 23))
        vc.initialScrollOffsetY = 300
        vc.loadViewIfNeeded()

        vc.view.frame = CGRect(x: 0, y: 0, width: 700, height: 600)
        vc.view.layoutIfNeeded()
        vc.viewDidLayoutSubviews()

        XCTAssertEqual(vc.scrollView.contentOffset.y, 300, accuracy: 1)
    }
}
