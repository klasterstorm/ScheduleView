import XCTest
@testable import MailScheduleView

final class WeekScheduleViewTests: XCTestCase {

    // MARK: - Инициализация

    func testInitCreatesSubviews() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))

        // 1 TimelineView + 7 сепараторов + 1 UIStackView = 9 прямых subviews
        XCTAssertEqual(view.subviews.count, 9)

        // UIStackView содержит 7 DayScheduleView
        let stack = view.subviews.compactMap { $0 as? UIStackView }.first
        XCTAssertNotNil(stack)
        XCTAssertEqual(stack?.arrangedSubviews.count, 7)
    }

    // MARK: - Intrinsic content size

    func testIntrinsicContentSize() {
        let view = WeekScheduleView<TestEvent>()
        view.config = ScheduleConfig(hourHeight: 60)
        XCTAssertEqual(view.intrinsicContentSize.height, 60 * 24)

        view.config = ScheduleConfig(hourHeight: 80)
        XCTAssertEqual(view.intrinsicContentSize.height, 80 * 24)
    }

    // MARK: - Day views в embedded режиме

    func testDayViewsAreEmbedded() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.events = []
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }
        XCTAssertEqual(dayViews.count, 7)

        for dayView in dayViews {
            XCTAssertEqual(dayView.displayMode, .embedded)
        }
    }

    // MARK: - Config пробрасывается в day views

    func testConfigPropagation() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.config = ScheduleConfig(hourHeight: 80, minEventHeight: 30)
        view.events = [] // триггер reload
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }

        for dayView in dayViews {
            XCTAssertEqual(dayView.config.hourHeight, 80)
            XCTAssertEqual(dayView.config.minEventHeight, 30)
        }
    }

    // MARK: - Layout колонок

    func testDayColumnLayout() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.timelineConfig = TimelineConfig(timeColumnWidth: 50)
        view.events = []
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!

        // Stack frame: x = eventsLeft, width = bounds.width - eventsLeft
        let expectedX = view.timelineConfig.eventsLeft
        let expectedWidth = 700 - expectedX
        XCTAssertEqual(stack.frame.origin.x, expectedX, accuracy: 0.5)
        XCTAssertEqual(stack.frame.width, expectedWidth, accuracy: 0.5)

        // Каждая колонка равной ширины
        let expectedDayWidth = expectedWidth / 7.0
        for dayView in stack.arrangedSubviews {
            XCTAssertEqual(dayView.frame.width, expectedDayWidth, accuracy: 0.5)
        }
    }

    // MARK: - События распределяются по дням

    func testSettingEventsDistributesAcrossDays() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.startOfWeek = makeDate(year: 2026, month: 3, day: 23)

        view.events = [
            TestEvent(id: "mon", start: makeDate(day: 23, hour: 9), end: makeDate(day: 23, hour: 10)),
            TestEvent(id: "wed", start: makeDate(day: 25, hour: 14), end: makeDate(day: 25, hour: 15)),
        ]
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }

        // Понедельник (индекс 0) — 1 событие (timeline subview + 1 event)
        XCTAssertEqual(dayViews[0].subviews.count, 2)

        // Вторник (индекс 1) — 0 событий
        XCTAssertEqual(dayViews[1].subviews.count, 1)

        // Среда (индекс 2) — 1 событие
        XCTAssertEqual(dayViews[2].subviews.count, 2)
    }

    // MARK: - viewForEvent получает оригинальное событие

    func testViewForEventReceivesOriginalEvent() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.startOfWeek = makeDate(year: 2026, month: 3, day: 23)

        var receivedIds: [String] = []
        view.viewForEvent = { event in
            receivedIds.append(event.id)
            return UIView()
        }

        view.events = [
            TestEvent(id: "event1", start: makeDate(day: 23, hour: 9), end: makeDate(day: 23, hour: 10)),
            TestEvent(id: "event2", start: makeDate(day: 24, hour: 14), end: makeDate(day: 24, hour: 15)),
        ]

        XCTAssertTrue(receivedIds.contains("event1"))
        XCTAssertTrue(receivedIds.contains("event2"))
    }

    // MARK: - Пустые события

    func testEmptyEvents() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.events = []
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }

        for dayView in dayViews {
            XCTAssertEqual(dayView.subviews.count, 1)
        }
    }

    // MARK: - Смена startOfWeek перераспределяет события

    func testStartOfWeekChangeRedistributesEvents() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.startOfWeek = makeDate(year: 2026, month: 3, day: 23)

        view.events = [
            TestEvent(id: "mon23", start: makeDate(day: 23, hour: 9), end: makeDate(day: 23, hour: 10)),
        ]
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }

        XCTAssertEqual(dayViews[0].subviews.count, 2)

        // Сдвигаем неделю — событие уходит за пределы
        view.startOfWeek = makeDate(year: 2026, month: 3, day: 24)
        view.layoutIfNeeded()

        for dayView in dayViews {
            XCTAssertEqual(dayView.subviews.count, 1)
        }
    }

    // MARK: - Default view без viewForEvent

    func testDefaultViewWhenNoViewForEvent() {
        let view = WeekScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.startOfWeek = makeDate(year: 2026, month: 3, day: 23)

        view.events = [
            TestEvent(start: makeDate(day: 23, hour: 9), end: makeDate(day: 23, hour: 10)),
        ]
        view.layoutIfNeeded()

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }

        XCTAssertEqual(dayViews[0].subviews.count, 2)
    }

    // MARK: - Инъекция resolver

    func testCustomResolverIsUsed() {
        let resolver = EventDayResolver<TestEvent>(timeZone: .current)
        let view = WeekScheduleView<TestEvent>(resolver: resolver, frame: CGRect(x: 0, y: 0, width: 700, height: 1440))
        view.startOfWeek = makeDate(year: 2026, month: 3, day: 23)

        view.events = [
            TestEvent(start: makeDate(day: 23, hour: 9), end: makeDate(day: 23, hour: 10)),
        ]

        let stack = view.subviews.compactMap { $0 as? UIStackView }.first!
        let dayViews = stack.arrangedSubviews.compactMap { $0 as? DayScheduleView<DaySlice<TestEvent>> }

        // Resolver корректно распределил событие
        XCTAssertEqual(dayViews[0].subviews.count, 2)
    }
}