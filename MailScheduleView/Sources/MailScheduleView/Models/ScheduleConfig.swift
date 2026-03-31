import UIKit

/// Параметры индикатора текущего времени.
///
/// Настраивает внешний вид красной линии «сейчас» в расписании.
/// Передаётся как часть `ScheduleConfig`.
public struct CurrentTimeIndicatorConfig {

    /// Цвет линии и маркера (по умолчанию `.systemRed`)
    public var color: UIColor

    /// Толщина горизонтальной линии в поинтах (по умолчанию `1.0`)
    public var lineHeight: CGFloat

    /// Радиус круглого маркера слева от линии (по умолчанию `5.0`)
    public var circleRadius: CGFloat

    /// Скрыть индикатор (по умолчанию `false`)
    public var isHidden: Bool

    /// - Parameters:
    ///   - color: цвет линии и маркера
    ///   - lineHeight: толщина линии
    ///   - circleRadius: радиус маркера
    ///   - isHidden: скрыть индикатор
    public init(
        color: UIColor = .systemRed,
        lineHeight: CGFloat = 1.0,
        circleRadius: CGFloat = 5.0,
        isHidden: Bool = false
    ) {
        self.color = color
        self.lineHeight = lineHeight
        self.circleRadius = circleRadius
        self.isHidden = isHidden
    }
}

/// Параметры отображения событий.
///
/// Определяет масштаб временной шкалы, минимальную высоту события
/// и настройки индикатора текущего времени. Используется всеми view расписания.
public struct ScheduleConfig {

    /// Высота одного часа в поинтах (по умолчанию `60`)
    public var hourHeight: CGFloat

    /// Минимальная высота события в поинтах (по умолчанию `20`)
    public var minEventHeight: CGFloat

    /// Параметры индикатора текущего времени
    public var currentTimeIndicator: CurrentTimeIndicatorConfig

    /// - Parameters:
    ///   - hourHeight: высота одного часа в поинтах
    ///   - minEventHeight: минимальная высота события
    ///   - currentTimeIndicator: параметры индикатора текущего времени
    public init(
        hourHeight: CGFloat = 60,
        minEventHeight: CGFloat = 20,
        currentTimeIndicator: CurrentTimeIndicatorConfig = CurrentTimeIndicatorConfig()
    ) {
        self.hourHeight = hourHeight
        self.minEventHeight = minEventHeight
        self.currentTimeIndicator = currentTimeIndicator
    }

    /// Высота минуты в поинтах
    internal var minuteHeight: CGFloat {
        hourHeight / 60.0
    }

    /// Минимальная визуальная длительность события в минутах
    internal var minDurationMinutes: CGFloat {
        minEventHeight / minuteHeight
    }

    /// Полная высота таймлайна (24 часа)
    internal var timelineHeight: CGFloat {
        hourHeight * 24
    }
}

/// Параметры временной шкалы (часовые метки и линии).
///
/// Определяет ширину колонки с метками времени слева от событий.
public struct TimelineConfig {

    /// Ширина колонки с метками времени (по умолчанию `50`)
    public var timeColumnWidth: CGFloat

    /// - Parameter timeColumnWidth: ширина колонки с метками времени
    public init(timeColumnWidth: CGFloat = 50) {
        self.timeColumnWidth = timeColumnWidth
    }

    /// Левая граница области событий (после колонки с метками)
    internal var eventsLeft: CGFloat {
        timeColumnWidth + 4
    }
}
