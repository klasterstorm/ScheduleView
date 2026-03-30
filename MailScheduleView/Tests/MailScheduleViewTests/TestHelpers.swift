import Foundation
@testable import MailScheduleView

/// Тестовая модель события
struct TestEvent: IScheduleEvent, Equatable {
    let id: String
    let start: Date
    let end: Date

    init(id: String = UUID().uuidString, start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }
}

/// Хелпер для создания дат
func makeDate(year: Int = 2026, month: Int = 3, day: Int = 22,
              hour: Int = 0, minute: Int = 0, second: Int = 0,
              timeZone: TimeZone = .current) -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = timeZone
    return cal.date(from: DateComponents(
        year: year, month: month, day: day,
        hour: hour, minute: minute, second: second
    ))!
}
