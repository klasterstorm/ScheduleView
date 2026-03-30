import Foundation

// MARK: - Day slice

/// Отрезок события, обрезанный до границ одного дня.
/// Хранит ссылку на оригинальное событие.
public struct DaySlice<Event: IScheduleEvent>: IScheduleEvent {
    /// Оригинальное событие (EAS, EWS, CalDAV и т.д.)
    public let original: Event
    /// Начало отрезка, обрезанное до границ дня
    public let start: Date
    /// Конец отрезка, обрезанный до границ дня
    public let end: Date
}

// MARK: - Resolver

/// Разрезает события по дням с учётом часового пояса.
///
/// День считается от 00:00 до 23:59.
///
/// Событие с 11-го 10:00 по 13-е 03:00 при запросе:
/// - 11-го → 10:00–23:59
/// - 12-го → 00:00–23:59 (весь день)
/// - 13-го → 00:00–03:00
///
/// ```
/// let resolver = EventDayResolver<EASEvent>(timeZone: .current)
/// let slices = resolver.resolve(events: allEvents, for: selectedDate)
/// scheduleView.events = slices
/// scheduleView.viewForEvent = { slice in
///     let v = MyView()
///     v.titleLabel.text = slice.original.subject
///     return v
/// }
/// scheduleView.onEventTapped = { slice in
///     print(slice.original) // оригинальный EASEvent
/// }
/// ```
public final class EventDayResolver<Event: IScheduleEvent> {

    private var calendar: Calendar

    public init(timeZone: TimeZone = .current) {
        var cal = Calendar.current
        cal.timeZone = timeZone
        self.calendar = cal
    }

    /// Обновить часовой пояс (например, при смене настроек пользователя)
    public var timeZone: TimeZone {
        get { calendar.timeZone }
        set { calendar.timeZone = newValue }
    }

    /// Возвращает отрезки событий, попадающих в указанный день.
    public func resolve(events: [Event], for date: Date) -> [DaySlice<Event>] {
        let dayStart = calendar.startOfDay(for: date)
        // Конец дня — 23:59:59
        guard let dayEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart) else {
            return []
        }

        var slices: [DaySlice<Event>] = []

        for event in events {
            // Событие не пересекается с этим днём
            guard event.start <= dayEnd && event.end > dayStart else { continue }

            let clampedStart = max(event.start, dayStart)
            let clampedEnd = min(event.end, dayEnd)

            slices.append(DaySlice(original: event, start: clampedStart, end: clampedEnd))
        }

        return slices
    }
}
