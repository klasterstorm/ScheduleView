import XCTest
@testable import ScheduleView

final class LayoutEventsTests: XCTestCase {

    // MARK: - Пустой ввод

    func testEmptyEvents() {
        let result = layoutEvents([TestEvent]())
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Одно событие

    func testSingleEvent() {
        let event = TestEvent(
            start: makeDate(hour: 9), end: makeDate(hour: 10)
        )
        let result = layoutEvents([event])

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].column, 0)
        XCTAssertEqual(result[0].totalColumns, 1)
    }

    // MARK: - Непересекающиеся события

    func testNonOverlappingEvents() {
        let events = [
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 11), end: makeDate(hour: 12)),
            TestEvent(id: "C", start: makeDate(hour: 14), end: makeDate(hour: 15)),
        ]
        let result = layoutEvents(events)

        XCTAssertEqual(result.count, 3)
        // Каждое событие в своём кластере — 1 колонка
        for layout in result {
            XCTAssertEqual(layout.column, 0)
            XCTAssertEqual(layout.totalColumns, 1)
        }
    }

    // MARK: - Два пересекающихся события

    func testTwoOverlappingEvents() {
        let events = [
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10, minute: 30)),
        ]
        let result = layoutEvents(events)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].column, 0)
        XCTAssertEqual(result[1].column, 1)
        XCTAssertEqual(result[0].totalColumns, 2)
        XCTAssertEqual(result[1].totalColumns, 2)
    }

    // MARK: - Три пересекающихся события

    func testThreeOverlappingEvents() {
        let events = [
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10, minute: 30)),
            TestEvent(id: "B", start: makeDate(hour: 9, minute: 15), end: makeDate(hour: 10, minute: 15)),
            TestEvent(id: "C", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10)),
        ]
        let result = layoutEvents(events)

        XCTAssertEqual(result.count, 3)
        // Все три в одном кластере — 3 колонки
        for layout in result {
            XCTAssertEqual(layout.totalColumns, 3)
        }
        let columns = Set(result.map { $0.column })
        XCTAssertEqual(columns, [0, 1, 2])
    }

    // MARK: - Событие заканчивается, когда другое начинается (граница)

    func testAdjacentEventsNoOverlap() {
        let events = [
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 10), end: makeDate(hour: 11)),
        ]
        let result = layoutEvents(events)

        XCTAssertEqual(result.count, 2)
        // end == start — не пересекаются, каждое в своём кластере
        XCTAssertEqual(result[0].totalColumns, 1)
        XCTAssertEqual(result[1].totalColumns, 1)
    }

    // MARK: - Переиспользование колонки

    func testColumnReuse() {
        // A и B пересекаются, C начинается после A заканчивается — может занять колонку A
        let events = [
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 11)),
            TestEvent(id: "C", start: makeDate(hour: 10), end: makeDate(hour: 10, minute: 30)),
        ]
        let result = layoutEvents(events)

        XCTAssertEqual(result.count, 3)
        let a = result.first { $0.event.id == "A" }!
        let b = result.first { $0.event.id == "B" }!
        let c = result.first { $0.event.id == "C" }!

        // A — колонка 0, B — колонка 1, C — переиспользует колонку 0
        XCTAssertEqual(a.column, 0)
        XCTAssertEqual(b.column, 1)
        XCTAssertEqual(c.column, 0)
        XCTAssertEqual(c.totalColumns, 2)
    }

    // MARK: - Смешанные кластеры

    func testMixedClusters() {
        let events = [
            // Кластер 1: пересекаются
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10, minute: 30)),
            // Кластер 2: одиночное
            TestEvent(id: "C", start: makeDate(hour: 14), end: makeDate(hour: 15)),
        ]
        let result = layoutEvents(events)

        let a = result.first { $0.event.id == "A" }!
        let b = result.first { $0.event.id == "B" }!
        let c = result.first { $0.event.id == "C" }!

        XCTAssertEqual(a.totalColumns, 2)
        XCTAssertEqual(b.totalColumns, 2)
        XCTAssertEqual(c.totalColumns, 1)
        XCTAssertEqual(c.column, 0)
    }

    // MARK: - Неотсортированный ввод

    func testUnsortedInput() {
        let events = [
            TestEvent(id: "C", start: makeDate(hour: 14), end: makeDate(hour: 15)),
            TestEvent(id: "A", start: makeDate(hour: 9), end: makeDate(hour: 10)),
            TestEvent(id: "B", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10, minute: 30)),
        ]
        let result = layoutEvents(events)

        // Алгоритм должен отсортировать сам
        XCTAssertEqual(result.count, 3)
        let a = result.first { $0.event.id == "A" }!
        let b = result.first { $0.event.id == "B" }!
        XCTAssertEqual(a.column, 0)
        XCTAssertEqual(b.column, 1)
    }
}
