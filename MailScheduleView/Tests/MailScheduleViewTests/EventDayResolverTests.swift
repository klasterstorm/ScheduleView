import XCTest
@testable import MailScheduleView

final class EventDayResolverTests: XCTestCase {

    private let utc = TimeZone(identifier: "UTC")!
    private lazy var resolver = EventDayResolver<TestEvent>(timeZone: utc)

    /// Хелпер: создаёт дату в UTC для тестов resolver
    private func utcDate(day: Int = 22, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        makeDate(day: day, hour: hour, minute: minute, second: second, timeZone: utc)
    }

    // MARK: - Событие целиком внутри дня

    func testEventWithinSameDay() {
        let event = TestEvent(
            start: utcDate(hour: 9), end: utcDate(hour: 17)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(hour: 12))

        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, event.start)
        XCTAssertEqual(slices[0].end, event.end)
    }

    // MARK: - Событие из другого дня не попадает

    func testEventOnDifferentDay() {
        let event = TestEvent(
            start: utcDate(day: 21, hour: 9), end: utcDate(day: 21, hour: 17)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 22))

        XCTAssertTrue(slices.isEmpty)
    }

    // MARK: - Переход через полночь — первый день

    func testCrossMidnightFirstDay() {
        let event = TestEvent(
            start: utcDate(day: 22, hour: 23), end: utcDate(day: 23, hour: 1)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 22))

        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, utcDate(day: 22, hour: 23))
        // Конец обрезан до 23:59:59
        let dayEnd = utcDate(day: 22, hour: 23, minute: 59, second: 59)
        XCTAssertEqual(slices[0].end, dayEnd)
    }

    // MARK: - Переход через полночь — второй день

    func testCrossMidnightSecondDay() {
        let event = TestEvent(
            start: utcDate(day: 22, hour: 23), end: utcDate(day: 23, hour: 1)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 23))

        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, utcDate(day: 23, hour: 0))
        XCTAssertEqual(slices[0].end, utcDate(day: 23, hour: 1))
    }

    // MARK: - Многодневное событие (11-го 10:00 → 13-го 03:00)

    func testMultiDayEventFirstDay() {
        let event = TestEvent(
            start: utcDate(day: 11, hour: 10), end: utcDate(day: 13, hour: 3)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 11))

        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, utcDate(day: 11, hour: 10))
        XCTAssertEqual(slices[0].end, utcDate(day: 11, hour: 23, minute: 59, second: 59))
    }

    func testMultiDayEventMiddleDay() {
        let event = TestEvent(
            start: utcDate(day: 11, hour: 10), end: utcDate(day: 13, hour: 3)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 12))

        XCTAssertEqual(slices.count, 1)
        // Весь день: 00:00–23:59:59
        XCTAssertEqual(slices[0].start, utcDate(day: 12, hour: 0))
        XCTAssertEqual(slices[0].end, utcDate(day: 12, hour: 23, minute: 59, second: 59))
    }

    func testMultiDayEventLastDay() {
        let event = TestEvent(
            start: utcDate(day: 11, hour: 10), end: utcDate(day: 13, hour: 3)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 13))

        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices[0].start, utcDate(day: 13, hour: 0))
        XCTAssertEqual(slices[0].end, utcDate(day: 13, hour: 3))
    }

    // MARK: - Сохранение оригинального события

    func testOriginalEventPreserved() {
        let event = TestEvent(
            id: "original-123",
            start: utcDate(day: 22, hour: 23), end: utcDate(day: 23, hour: 1)
        )
        let slices = resolver.resolve(events: [event], for: utcDate(day: 22))

        XCTAssertEqual(slices[0].original.id, "original-123")
        XCTAssertEqual(slices[0].original, event)
    }

    // MARK: - Пустой ввод

    func testEmptyEvents() {
        let slices = resolver.resolve(events: [], for: utcDate())
        XCTAssertTrue(slices.isEmpty)
    }

    // MARK: - Несколько событий, часть попадает

    func testMultipleEventsMixed() {
        let events = [
            TestEvent(id: "A", start: utcDate(day: 22, hour: 9), end: utcDate(day: 22, hour: 10)),
            TestEvent(id: "B", start: utcDate(day: 21, hour: 9), end: utcDate(day: 21, hour: 10)),
            TestEvent(id: "C", start: utcDate(day: 22, hour: 14), end: utcDate(day: 22, hour: 15)),
        ]
        let slices = resolver.resolve(events: events, for: utcDate(day: 22))

        XCTAssertEqual(slices.count, 2)
        let ids = slices.map { $0.original.id }
        XCTAssertTrue(ids.contains("A"))
        XCTAssertTrue(ids.contains("C"))
        XCTAssertFalse(ids.contains("B"))
    }

    // MARK: - Смена часового пояса

    func testTimeZoneChange() {
        // Событие в UTC: 22-го 23:30–23-го 00:30
        let event = TestEvent(
            start: utcDate(day: 22, hour: 23, minute: 30),
            end: utcDate(day: 23, hour: 0, minute: 30)
        )

        // В UTC+3 это будет 23-го 02:30–03:30 — не попадает в 22-е
        let moscowTZ = TimeZone(secondsFromGMT: 3 * 3600)!
        let moscowResolver = EventDayResolver<TestEvent>(timeZone: moscowTZ)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = moscowTZ
        let march22Moscow = cal.date(from: DateComponents(year: 2026, month: 3, day: 22))!

        let slices = moscowResolver.resolve(events: [event], for: march22Moscow)
        XCTAssertTrue(slices.isEmpty)

        // Но попадает в 23-е по Москве
        let march23Moscow = cal.date(from: DateComponents(year: 2026, month: 3, day: 23))!
        let slices23 = moscowResolver.resolve(events: [event], for: march23Moscow)
        XCTAssertEqual(slices23.count, 1)
    }

    // MARK: - Обновление timeZone через свойство

    func testTimeZonePropertyUpdate() {
        let resolver = EventDayResolver<TestEvent>(timeZone: utc)
        XCTAssertEqual(resolver.timeZone, utc)

        let moscow = TimeZone(secondsFromGMT: 3 * 3600)!
        resolver.timeZone = moscow
        XCTAssertEqual(resolver.timeZone, moscow)
    }
}
