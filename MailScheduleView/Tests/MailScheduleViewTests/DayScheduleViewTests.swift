import XCTest
@testable import MailScheduleView

final class DayScheduleViewTests: XCTestCase {

    // MARK: - Инициализация

    func testInitCreatesTimelineView() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))

        // 2 subviews — TimelineView + CurrentTimeIndicatorView
        XCTAssertEqual(view.subviews.count, 2)
    }

    // MARK: - Intrinsic content size

    func testIntrinsicContentSize() {
        let view = DayScheduleView<TestEvent>()
        view.config = ScheduleConfig(hourHeight: 60)
        XCTAssertEqual(view.intrinsicContentSize.height, 60 * 24)

        view.config = ScheduleConfig(hourHeight: 80)
        XCTAssertEqual(view.intrinsicContentSize.height, 80 * 24)
    }

    // MARK: - Установка событий создаёт subviews

    func testSettingEventsAddsSubviews() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        let baseSubviewCount = view.subviews.count

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(start: makeDate(hour: 14), end: makeDate(hour: 15)),
        ]

        XCTAssertEqual(view.subviews.count, baseSubviewCount + 2)
    }

    // MARK: - Переустановка событий заменяет subviews

    func testResettingEventsReplacesSubviews() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        let baseSubviewCount = view.subviews.count

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(start: makeDate(hour: 14), end: makeDate(hour: 15)),
        ]
        XCTAssertEqual(view.subviews.count, baseSubviewCount + 2)

        view.events = [
            TestEvent(start: makeDate(hour: 11), end: makeDate(hour: 12)),
        ]
        XCTAssertEqual(view.subviews.count, baseSubviewCount + 1)
    }

    // MARK: - Очистка событий

    func testClearingEventsRemovesSubviews() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        let baseSubviewCount = view.subviews.count

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
        ]
        XCTAssertEqual(view.subviews.count, baseSubviewCount + 1)

        view.events = []
        XCTAssertEqual(view.subviews.count, baseSubviewCount)
    }

    // MARK: - viewForEvent вызывается

    func testViewForEventClosure() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        var calledCount = 0

        view.viewForEvent = { _ in
            calledCount += 1
            let v = UIView()
            v.backgroundColor = .red
            return v
        }

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(start: makeDate(hour: 14), end: makeDate(hour: 15)),
        ]

        XCTAssertEqual(calledCount, 2)
    }

    // MARK: - viewForEvent получает правильное событие

    func testViewForEventReceivesCorrectEvent() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        var receivedIds: [String] = []

        view.viewForEvent = { event in
            receivedIds.append(event.id)
            return UIView()
        }

        view.events = [
            TestEvent(id: "first", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "second", start: makeDate(hour: 14), end: makeDate(hour: 15)),
        ]

        XCTAssertTrue(receivedIds.contains("first"))
        XCTAssertTrue(receivedIds.contains("second"))
    }

    // MARK: - Дефолтный view создаётся без viewForEvent

    func testDefaultViewWhenNoViewForEvent() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        let baseCount = view.subviews.count

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
        ]
        XCTAssertEqual(view.subviews.count, baseCount + 1)
    }

    // MARK: - Layout: событие позиционируется корректно

    func testEventViewPositioning() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.config = ScheduleConfig(hourHeight: 60)
        view.timelineConfig = TimelineConfig(timeColumnWidth: 50)

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
        ]
        view.layoutIfNeeded()

        let eventView = view.subviews.last!
        let expectedY: CGFloat = 9 * 60  // 540
        let expectedH: CGFloat = 60

        XCTAssertEqual(eventView.frame.origin.y, expectedY, accuracy: 0.5)
        XCTAssertEqual(eventView.frame.size.height, expectedH, accuracy: 0.5)
    }

    // MARK: - Layout: пересекающиеся события делят ширину

    func testOverlappingEventsShareWidth() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.config = ScheduleConfig(hourHeight: 60)
        view.timelineConfig = TimelineConfig(timeColumnWidth: 50)

        view.events = [
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10, minute: 30)),
        ]
        view.layoutIfNeeded()

        // subviews[0] = TimelineView, subviews[1] = CurrentTimeIndicatorView, subviews[2..3] = events
        let eventViewA = view.subviews[2]
        let eventViewB = view.subviews[3]

        let eventsWidth = 320 - 50 - 4 // bounds.width - timeColumnWidth - 4
        let expectedColumnWidth = CGFloat(eventsWidth) / 2.0

        XCTAssertEqual(eventViewA.frame.width, expectedColumnWidth - 2, accuracy: 0.5)
        XCTAssertEqual(eventViewB.frame.width, expectedColumnWidth - 2, accuracy: 0.5)
        XCTAssertNotEqual(eventViewA.frame.origin.x, eventViewB.frame.origin.x)
    }

    // MARK: - Gesture recognizer добавлен

    func testEventViewsHaveGestureRecognizer() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
        ]

        let eventView = view.subviews.last!
        let tapGestures = eventView.gestureRecognizers?.compactMap { $0 as? UITapGestureRecognizer } ?? []
        XCTAssertEqual(tapGestures.count, 1)
        XCTAssertTrue(eventView.isUserInteractionEnabled)
    }

    // MARK: - Config применяется

    func testConfigApplied() {
        let view = DayScheduleView<TestEvent>()
        view.config = ScheduleConfig(hourHeight: 80, minEventHeight: 30)
        view.timelineConfig = TimelineConfig(timeColumnWidth: 60)

        XCTAssertEqual(view.intrinsicContentSize.height, 80 * 24)
        XCTAssertEqual(view.config.minEventHeight, 30)
        XCTAssertEqual(view.timelineConfig.timeColumnWidth, 60)
    }

    // MARK: - DisplayMode

    func testDisplayModeDefaultsToStandalone() {
        let view = DayScheduleView<TestEvent>()
        XCTAssertEqual(view.displayMode, .standalone)
    }

    func testEmbeddedModeEventsStartAtZero() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 200, height: 1440))
        view.displayMode = .embedded
        view.config = ScheduleConfig(hourHeight: 60)

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
        ]
        view.layoutIfNeeded()

        let eventView = view.subviews.last!
        // Без таймлайна событие начинается с x ≈ 0 (inset = 1)
        XCTAssertEqual(eventView.frame.origin.x, 1, accuracy: 0.5)
    }

    // MARK: - DefaultViewFactory подменяема

    func testCustomDefaultViewFactory() {
        let view = DayScheduleView<TestEvent>(frame: CGRect(x: 0, y: 0, width: 320, height: 1440))
        view.defaultViewFactory = {
            let v = UIView()
            v.backgroundColor = .red
            v.layer.cornerRadius = 10
            return v
        }

        view.events = [
            TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10)),
        ]

        let eventView = view.subviews.last!
        XCTAssertEqual(eventView.backgroundColor, .red)
        XCTAssertEqual(eventView.layer.cornerRadius, 10)
    }
}

// MARK: - DisplayMode Equatable для тестов

extension DisplayMode: Equatable {}
