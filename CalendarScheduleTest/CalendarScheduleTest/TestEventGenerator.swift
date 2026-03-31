import Foundation
import MailScheduleView

/// Генерирует тестовые события для демонстрации расписания.
enum TestEventGenerator {

    /// Создаёт набор событий на ±7 дней от сегодня.
    static func generate() -> [ExampleCalendarEvent] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var events: [ExampleCalendarEvent] = []

        for dayOffset in -7...7 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = cal.component(.weekday, from: day)

            // Стендап каждый будний день
            if (2...6).contains(weekday) {
                events.append(event(on: day, from: (9, 30), to: (9, 45), title: "Стендап"))
            }

            // Обед каждый день
            events.append(event(on: day, from: (12, 30), to: (13, 30), title: "Обед"))

            // Уникальные события по дням
            events.append(contentsOf: uniqueEvents(for: dayOffset, day: day))
        }

        return events
    }

    // MARK: - Private

    private static func uniqueEvents(for dayOffset: Int, day: Date) -> [ExampleCalendarEvent] {
        switch dayOffset {
        case -7:
            return [event(on: day, from: (10, 0), to: (11, 30), title: "Планирование спринта")]
        case -6:
            return [
                event(on: day, from: (14, 0), to: (15, 0), title: "1-on-1 с тимлидом"),
                event(on: day, from: (16, 0), to: (17, 30), title: "Архитектурный ревью"),
            ]
        case -5:
            return [
                event(on: day, from: (11, 0), to: (12, 0), title: "Демо заказчику"),
                event(on: day, from: (15, 0), to: (15, 30), title: "Код-ревью: PR #142"),
            ]
        case -4:
            return [
                event(on: day, from: (10, 0), to: (10, 30), title: "Собеседование (скрининг)"),
                event(on: day, from: (14, 0), to: (16, 0), title: "Хакатон: прототип"),
            ]
        case -3:
            return [
                event(on: day, from: (8, 0), to: (8, 30), title: "Зарядка"),
                event(on: day, from: (15, 0), to: (16, 30), title: "Ретроспектива"),
            ]
        case -2, -1:
            return []
        case 0:
            return [
                event(on: day, from: (10, 0), to: (11, 0), title: "Груминг бэклога"),
                event(on: day, from: (11, 0), to: (11, 45), title: "Синк с бэкендом"),
                event(on: day, from: (14, 0), to: (15, 0), title: "Код-ревью: PR #158"),
                event(on: day, from: (16, 0), to: (17, 0), title: "Тех.долг: рефакторинг"),
                event(on: day, from: (17, 30), to: (18, 0), title: "Английский с репетитором"),
            ]
        case 1:
            return [
                event(on: day, from: (10, 0), to: (12, 0), title: "Воркшоп: SwiftUI"),
                event(on: day, from: (14, 30), to: (15, 30), title: "Менторинг джуна"),
            ]
        case 2:
            return [
                event(on: day, from: (11, 0), to: (11, 30), title: "Дизайн-ревью"),
                event(on: day, from: (15, 0), to: (16, 0), title: "1-on-1 с тимлидом"),
                event(on: day, from: (16, 0), to: (16, 30), title: "Собеседование (тех.)"),
            ]
        case 3:
            return [
                event(on: day, from: (10, 0), to: (11, 30), title: "Планирование спринта"),
                event(on: day, from: (14, 0), to: (14, 30), title: "Релиз-чеклист"),
            ]
        case 4:
            return [event(on: day, from: (11, 0), to: (12, 15), title: "Демо заказчику")]
        case 6:
            return [event(on: day, from: (10, 0), to: (11, 30), title: "Бег в парке")]
        default:
            return [event(on: day, from: (10, 0), to: (11, 0), title: "Встреча")]
        }
    }

    private static func event(
        on day: Date,
        from start: (Int, Int),
        to end: (Int, Int),
        title: String
    ) -> ExampleCalendarEvent {
        let cal = Calendar.current
        return ExampleCalendarEvent(
            startDate: cal.date(byAdding: DateComponents(hour: start.0, minute: start.1), to: day)!,
            endDate: cal.date(byAdding: DateComponents(hour: end.0, minute: end.1), to: day)!,
            title: title
        )
    }
}
