import UIKit

/// Делегат для запроса событий извне.
///
/// `ICalendarSchedulePageView` вызывает этот делегат когда нужно загрузить события
/// для нового контроллера расписания (при свайпе или программной навигации).
public protocol ICalendarSchedulePageControllerDelegate: AnyObject {

    /// Запрашивает события для контроллера расписания.
    ///
    /// Реализация должна получить события за `schedule.dateRange` и передать их
    /// через `schedule.showEvents()` и `schedule.showAllDayEvents()`.
    /// - Parameter schedule: контроллер, для которого нужны события
    func eventsRequested(for schedule: IScheduleViewController)
}

/// Протокол страничного view расписания.
///
/// Содержит `UIPageViewController` для горизонтальной навигации
/// между страницами расписания (день/неделя/месяц).
public protocol ICalendarSchedulePageView: UIView {

    /// Делегат для запроса событий при навигации.
    var delegate: ICalendarSchedulePageControllerDelegate? { get set }

    /// Принудительно переходит к указанной дате.
    ///
    /// При переходе автоматически вызывается `delegate.eventsRequested`.
    /// - Parameter date: дата для отображения
    func scroll(to date: Date)
}
