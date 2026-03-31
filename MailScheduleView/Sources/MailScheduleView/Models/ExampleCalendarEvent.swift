import Foundation

/// Пример модели события календаря.
///
/// Демонстрационная реализация `IScheduleEvent`. Потребитель библиотеки
/// должен создать свою модель, реализующую `IScheduleEvent`,
/// под конкретный календарный бэкенд (EAS, EWS, CalDAV и т.д.).
public struct ExampleCalendarEvent: IScheduleEvent {

    /// Дата и время начала события
    public let startDate: Date

    /// Дата и время окончания события
    public let endDate: Date

    /// Заголовок события
    public let title: String

    /// Начало события (требование `IScheduleEvent`)
    public var start: Date { startDate }

    /// Конец события (требование `IScheduleEvent`)
    public var end: Date { endDate }

    public init(startDate: Date, endDate: Date, title: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
    }
}
