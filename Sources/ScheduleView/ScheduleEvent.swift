import UIKit

// MARK: - Protocol

/// Минимальный протокол для события. Только временные рамки.
public protocol IScheduleEvent {
    var start: Date { get }
    var end: Date { get }
}

extension IScheduleEvent {

    func startMinutes(in calendar: Calendar = .current) -> CGFloat {
        let comps = calendar.dateComponents([.hour, .minute], from: start)
        return CGFloat(comps.hour! * 60 + comps.minute!)
    }

    func endMinutes(in calendar: Calendar = .current) -> CGFloat {
        let comps = calendar.dateComponents([.hour, .minute], from: end)
        return CGFloat(comps.hour! * 60 + comps.minute!)
    }
}
