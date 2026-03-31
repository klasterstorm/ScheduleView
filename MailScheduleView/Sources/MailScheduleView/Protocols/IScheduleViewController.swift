import UIKit

/// Протокол контроллера расписания.
///
/// Определяет единый интерфейс для всех режимов отображения (день, неделя, месяц).
/// Потребитель запрашивает события через `dateRange` и передаёт их через `showEvents`/`showAllDayEvents`.
public protocol IScheduleViewController: UIViewController {

    /// Временной интервал, покрываемый данным контроллером.
    ///
    /// Для дневного режима — один день, для недельного — 7 дней, для месячного — полный месяц.
    var dateRange: ScheduleDateRange { get }

    /// Отображает тайминговые события (с конкретным временем начала и конца).
    /// - Parameter events: массив событий для отображения
    func showEvents(events: [ExampleCalendarEvent])

    /// Отображает события на весь день (all-day events).
    /// - Parameter events: массив событий на весь день
    func showAllDayEvents(events: [ExampleCalendarEvent])

    /// Скроллит к текущему времени.
    /// - Parameter animated: анимировать ли скролл
    func scrollToCurrentTime(animated: Bool)

    /// Текущая вертикальная позиция скролла.
    var scrollOffsetY: CGFloat { get set }

    /// Начальная позиция скролла, применяется при первом layout.
    /// Если `nil` — скроллит к текущему времени.
    var initialScrollOffsetY: CGFloat? { get set }
}
