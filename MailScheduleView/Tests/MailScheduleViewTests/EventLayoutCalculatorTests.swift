import XCTest
@testable import MailScheduleView

final class EventLayoutCalculatorTests: XCTestCase {

    // MARK: - calculateEventFrames: одно событие

    func testSingleEventFrame() {
        let event = TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10))
        let layouts = [EventLayout(event: event, column: 0, totalColumns: 1)]
        let config = ScheduleConfig(hourHeight: 60)

        let frames = calculateEventFrames(
            layouts: layouts,
            containerWidth: 320,
            leftOffset: 0,
            config: config
        )

        XCTAssertEqual(frames.count, 1)
        XCTAssertEqual(frames[0].frame.origin.y, 9 * 60, accuracy: 0.5)
        XCTAssertEqual(frames[0].frame.size.height, 60, accuracy: 0.5)
        // width = containerWidth / 1 - 2 (inset * 2)
        XCTAssertEqual(frames[0].frame.size.width, 318, accuracy: 0.5)
    }

    // MARK: - calculateEventFrames: два события в двух колонках

    func testTwoColumnsEventFrames() {
        let eventA = TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10))
        let eventB = TestEvent(start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10, minute: 30))
        let layouts = [
            EventLayout(event: eventA, column: 0, totalColumns: 2),
            EventLayout(event: eventB, column: 1, totalColumns: 2),
        ]
        let config = ScheduleConfig(hourHeight: 60)

        let frames = calculateEventFrames(
            layouts: layouts,
            containerWidth: 320,
            leftOffset: 0,
            config: config
        )

        XCTAssertEqual(frames.count, 2)
        // Каждая колонка = 160, ширина = 160 - 2 = 158
        XCTAssertEqual(frames[0].frame.width, 158, accuracy: 0.5)
        XCTAssertEqual(frames[1].frame.width, 158, accuracy: 0.5)
        // Разные x-позиции
        XCTAssertNotEqual(frames[0].frame.origin.x, frames[1].frame.origin.x)
    }

    // MARK: - calculateEventFrames: leftOffset учитывается

    func testLeftOffsetApplied() {
        let event = TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10))
        let layouts = [EventLayout(event: event, column: 0, totalColumns: 1)]
        let config = ScheduleConfig(hourHeight: 60)

        let frames = calculateEventFrames(
            layouts: layouts,
            containerWidth: 320,
            leftOffset: 54, // timeColumnWidth(50) + 4
            config: config
        )

        XCTAssertEqual(frames[0].frame.origin.x, 55, accuracy: 0.5) // 54 + inset(1)
    }

    // MARK: - calculateEventFrames: minEventHeight

    func testMinEventHeightApplied() {
        let event = TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 9, minute: 5))
        let layouts = [EventLayout(event: event, column: 0, totalColumns: 1)]
        let config = ScheduleConfig(hourHeight: 60, minEventHeight: 20)

        let frames = calculateEventFrames(
            layouts: layouts,
            containerWidth: 320,
            leftOffset: 0,
            config: config
        )

        // 5 минут * 1 pt/min = 5 pt, но minEventHeight = 20
        XCTAssertEqual(frames[0].frame.height, 20, accuracy: 0.5)
    }

    // MARK: - calculateEventFrames: сдвиг пересекающихся событий в одной колонке

    func testColumnBottomsShift() {
        // Два события в одной колонке, второе начинается раньше конца первого
        let eventA = TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10))
        let eventB = TestEvent(start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10, minute: 30))
        let layouts = [
            EventLayout(event: eventA, column: 0, totalColumns: 1),
            EventLayout(event: eventB, column: 0, totalColumns: 1),
        ]
        let config = ScheduleConfig(hourHeight: 60)

        let frames = calculateEventFrames(
            layouts: layouts,
            containerWidth: 320,
            leftOffset: 0,
            config: config
        )

        // Второе событие сдвигается вниз за конец первого
        let firstBottom = frames[0].frame.maxY
        XCTAssertGreaterThanOrEqual(frames[1].frame.origin.y, firstBottom)
    }

    // MARK: - calculateEventFrames: пустой массив

    func testEmptyLayouts() {
        let frames = calculateEventFrames(
            layouts: [EventLayout<TestEvent>](),
            containerWidth: 320,
            leftOffset: 0,
            config: ScheduleConfig()
        )

        XCTAssertTrue(frames.isEmpty)
    }
}
