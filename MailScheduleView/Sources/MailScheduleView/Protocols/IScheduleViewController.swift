import UIKit

/// Протокол контроллера расписания.
///
/// Определяет единый интерфейс для всех режимов отображения (день, неделя, месяц).
/// Потребитель передаёт события вместе с замыканиями для отображения и обработки тапов:
/// ```
/// schedule.showEvents(
///     events: myEvents,
///     viewForEvent: { event in
///         let label = UILabel()
///         label.text = (event as? MyEvent)?.title
///         return label
///     },
///     onEventTapped: { event in
///         print("Тап: \(event)")
///     }
/// )
/// ```
public protocol IScheduleViewController: UIViewController {

    /// Временной интервал, покрываемый данным контроллером.
    var dateRange: ScheduleDateRange { get }

    /// Отображает тайминговые события.
    /// - Parameters:
    ///   - events: массив событий для отображения
    ///   - viewForEvent: фабрика view для каждого события
    ///   - onEventTapped: обработчик тапа по событию (опционально)
    func showEvents(
        events: [IScheduleEvent],
        viewForEvent: @escaping (IScheduleEvent) -> UIView,
        onEventTapped: ((IScheduleEvent) -> Void)?
    )

    /// Отображает события на весь день (all-day events).
    /// - Parameters:
    ///   - events: массив событий на весь день
    ///   - viewForEvent: фабрика view для каждого события
    ///   - onEventTapped: обработчик тапа по событию (опционально)
    func showAllDayEvents(
        events: [IScheduleEvent],
        viewForEvent: @escaping (IScheduleEvent) -> UIView,
        onEventTapped: ((IScheduleEvent) -> Void)?
    )

    /// Скроллит к текущему времени.
    /// - Parameter animated: анимировать ли скролл
    func scrollToCurrentTime(animated: Bool)

    /// Текущая вертикальная позиция скролла.
    var scrollOffsetY: CGFloat { get set }

    /// Начальная позиция скролла, применяется при первом layout.
    /// Если `nil` — скроллит к текущему времени.
    var initialScrollOffsetY: CGFloat? { get set }
}
