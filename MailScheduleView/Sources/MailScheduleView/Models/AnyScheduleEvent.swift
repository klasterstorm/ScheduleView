import Foundation

/// Type-erased обёртка над `IScheduleEvent`.
///
/// Позволяет использовать `DayScheduleView<AnyScheduleEvent>` и `WeekScheduleView<AnyScheduleEvent>`
/// с любыми моделями событий без привязки к конкретному типу.
public struct AnyScheduleEvent: IScheduleEvent {

    /// Оригинальное событие
    public let wrapped: IScheduleEvent

    public var start: Date { wrapped.start }
    public var end: Date { wrapped.end }

    public init(_ event: IScheduleEvent) {
        self.wrapped = event
    }
}
