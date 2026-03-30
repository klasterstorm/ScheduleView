import UIKit

/// Параметры отображения событий (нужны всем view расписания).
public struct ScheduleConfig {
    /// Высота одного часа в поинтах
    public var hourHeight: CGFloat

    /// Минимальная высота события в поинтах
    public var minEventHeight: CGFloat

    public init(
        hourHeight: CGFloat = 60,
        minEventHeight: CGFloat = 20
    ) {
        self.hourHeight = hourHeight
        self.minEventHeight = minEventHeight
    }

    /// Высота минуты в поинтах
    var minuteHeight: CGFloat {
        hourHeight / 60.0
    }

    /// Минимальная визуальная длительность события в минутах
    var minDurationMinutes: CGFloat {
        minEventHeight / minuteHeight
    }

    /// Полная высота таймлайна (24 часа)
    var timelineHeight: CGFloat {
        hourHeight * 24
    }
}

/// Параметры временной шкалы (часовые метки и линии).
public struct TimelineConfig {
    /// Ширина колонки с метками времени
    public var timeColumnWidth: CGFloat

    public init(timeColumnWidth: CGFloat = 50) {
        self.timeColumnWidth = timeColumnWidth
    }

    /// Левая граница области событий (после колонки с метками)
    var eventsLeft: CGFloat {
        timeColumnWidth + 4
    }
}
