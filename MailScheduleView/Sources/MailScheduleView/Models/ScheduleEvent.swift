import UIKit

/// Минимальный протокол события расписания.
///
/// Требует только временные рамки (`start`/`end`). Не навязывает заголовок, цвет
/// или другие свойства — это позволяет использовать любую модель события
/// (EAS, EWS, CalDAV и т.д.) без адаптеров.
public protocol IScheduleEvent {
    /// Дата и время начала события
    var start: Date { get }
    /// Дата и время окончания события
    var end: Date { get }
}

extension IScheduleEvent {

    /// Минуты от полуночи для времени начала события.
    /// - Parameter calendar: календарь для извлечения компонентов (по умолчанию `.current`)
    internal func startMinutes(in calendar: Calendar = .current) -> CGFloat {
        let comps = calendar.dateComponents([.hour, .minute], from: start)
        return CGFloat(comps.hour! * 60 + comps.minute!)
    }

    /// Минуты от полуночи для времени окончания события.
    /// - Parameter calendar: календарь для извлечения компонентов (по умолчанию `.current`)
    internal func endMinutes(in calendar: Calendar = .current) -> CGFloat {
        let comps = calendar.dateComponents([.hour, .minute], from: end)
        return CGFloat(comps.hour! * 60 + comps.minute!)
    }
}
