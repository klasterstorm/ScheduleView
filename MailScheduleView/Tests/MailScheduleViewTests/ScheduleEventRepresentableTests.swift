import XCTest
@testable import MailScheduleView

final class ScheduleEventRepresentableTests: XCTestCase {

    // MARK: - startMinutes

    func testStartMinutesMidnight() {
        let event = TestEvent(start: makeDate(hour: 0, minute: 0), end: makeDate(hour: 1))
        XCTAssertEqual(event.startMinutes(), 0)
    }

    func testStartMinutesMorning() {
        let event = TestEvent(start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10))
        XCTAssertEqual(event.startMinutes(), 570) // 9*60 + 30
    }

    func testStartMinutesEndOfDay() {
        let event = TestEvent(start: makeDate(hour: 23, minute: 59), end: makeDate(hour: 23, minute: 59))
        XCTAssertEqual(event.startMinutes(), 1439) // 23*60 + 59
    }

    // MARK: - endMinutes

    func testEndMinutes() {
        let event = TestEvent(start: makeDate(hour: 9), end: makeDate(hour: 10, minute: 15))
        XCTAssertEqual(event.endMinutes(), 615) // 10*60 + 15
    }

    // MARK: - Calendar injection

    func testStartMinutesWithCalendar() {
        let event = TestEvent(start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10))
        let cal = Calendar.current
        XCTAssertEqual(event.startMinutes(in: cal), 570)
    }

    // MARK: - DaySlice сохраняет протокол

    func testDaySliceConformsToProtocol() {
        let original = TestEvent(id: "orig", start: makeDate(hour: 9), end: makeDate(hour: 17))
        let slice = DaySlice(original: original, start: makeDate(hour: 10), end: makeDate(hour: 15))

        XCTAssertEqual(slice.startMinutes(), 600) // 10*60
        XCTAssertEqual(slice.endMinutes(), 900)   // 15*60
        XCTAssertEqual(slice.original.id, "orig")
    }
}
