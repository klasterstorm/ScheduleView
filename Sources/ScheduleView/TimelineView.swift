import UIKit

/// Отрисовка временной сетки (часовые линии + метки 00:00–24:00).
/// Используется как subview в DayScheduleView и WeekScheduleView.
final class TimelineView: UIView {

    private var hourLabels: [UILabel] = []
    private var hourLines: [UIView] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        isUserInteractionEnabled = false

        for hour in 0..<25 {
            let line = UIView()
            line.backgroundColor = UIColor.separator
            addSubview(line)
            hourLines.append(line)

            if hour > 0 && hour < 24 {
                let label = UILabel()
                label.text = String(format: "%02d:00", hour)
                label.font = .systemFont(ofSize: 11)
                label.textColor = .secondaryLabel
                label.textAlignment = .right
                addSubview(label)
                hourLabels.append(label)
            }
        }
    }

    // MARK: - Layout

    /// Раскладывает линии и метки.
    /// - Parameters:
    ///   - config: конфигурация расписания (hourHeight)
    ///   - timelineConfig: конфигурация таймлайна (timeColumnWidth, eventsLeft)
    ///   - topOffset: отступ сверху (например, для заголовка дней недели)
    ///   - totalWidth: полная ширина контейнера
    func layoutTimeline(config: ScheduleConfig, timelineConfig: TimelineConfig, topOffset: CGFloat = 0, totalWidth: CGFloat) {
        for (i, line) in hourLines.enumerated() {
            let y = topOffset + CGFloat(i) * config.hourHeight
            line.frame = CGRect(x: timelineConfig.eventsLeft, y: y, width: totalWidth - timelineConfig.eventsLeft, height: 0.5)
        }

        for (i, label) in hourLabels.enumerated() {
            let hour = i + 1 // метки начинаются с 01:00
            let y = topOffset + CGFloat(hour) * config.hourHeight
            label.frame = CGRect(x: 0, y: y - 8, width: timelineConfig.timeColumnWidth, height: 16)
        }
    }
}
