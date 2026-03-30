import XCTest
import SnapshotTesting
@testable import ScheduleView

final class WeekScheduleViewSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // isRecording = true
    }

    // MARK: - Helpers

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Понедельник
        cal.timeZone = .current
        return cal
    }

    private func monday() -> Date {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday - cal.firstWeekday + 7) % 7
        return cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
    }

    private func makeDate(dayOffset: Int, hour: Int, minute: Int = 0) -> Date {
        let cal = calendar
        let base = monday()
        let day = cal.date(byAdding: .day, value: dayOffset, to: base)!
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    private func makeWeekView(
        events: [SimpleWeekEvent],
        hourHeight: CGFloat = 60
    ) -> WeekScheduleView<SimpleWeekEvent> {
        let config = ScheduleConfig(hourHeight: hourHeight)
        let view = WeekScheduleView<SimpleWeekEvent>(frame: CGRect(x: 0, y: 0, width: 750, height: config.timelineHeight))
        view.config = config
        view.startOfWeek = monday()
        view.backgroundColor = .systemBackground
        view.viewForEvent = { event in
            let v = UIView()
            v.backgroundColor = event.color.withAlphaComponent(0.85)
            v.layer.cornerRadius = 4
            v.clipsToBounds = true

            let label = UILabel()
            label.text = event.title
            label.font = .systemFont(ofSize: 10, weight: .semibold)
            label.textColor = .white
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: v.topAnchor, constant: 2),
                label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 2),
                label.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -2),
            ])
            return v
        }
        view.events = events
        view.layoutIfNeeded()
        return view
    }

    // MARK: - Типичная рабочая неделя

    func testTypicalWeek() {
        let events: [SimpleWeekEvent] = [
            // Понедельник
            SimpleWeekEvent(title: "Standup", start: makeDate(dayOffset: 0, hour: 9), end: makeDate(dayOffset: 0, hour: 9, minute: 30), color: .systemBlue),
            SimpleWeekEvent(title: "Planning", start: makeDate(dayOffset: 0, hour: 10), end: makeDate(dayOffset: 0, hour: 11, minute: 30), color: .systemPurple),
            // Вторник — пересечение
            SimpleWeekEvent(title: "Design", start: makeDate(dayOffset: 1, hour: 9), end: makeDate(dayOffset: 1, hour: 10, minute: 30), color: .systemGreen),
            SimpleWeekEvent(title: "1:1", start: makeDate(dayOffset: 1, hour: 9, minute: 30), end: makeDate(dayOffset: 1, hour: 10), color: .systemOrange),
            // Среда
            SimpleWeekEvent(title: "Workshop", start: makeDate(dayOffset: 2, hour: 14), end: makeDate(dayOffset: 2, hour: 16), color: .systemTeal),
            // Четверг
            SimpleWeekEvent(title: "Review", start: makeDate(dayOffset: 3, hour: 11), end: makeDate(dayOffset: 3, hour: 12), color: .systemRed),
            SimpleWeekEvent(title: "Lunch", start: makeDate(dayOffset: 3, hour: 12), end: makeDate(dayOffset: 3, hour: 13), color: .systemYellow),
            // Пятница
            SimpleWeekEvent(title: "Retro", start: makeDate(dayOffset: 4, hour: 16), end: makeDate(dayOffset: 4, hour: 17), color: .systemIndigo),
        ]

        let view = makeWeekView(events: events)
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Пустая неделя

    func testEmptyWeek() {
        let view = makeWeekView(events: [])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Переходящее событие через несколько дней

    func testMultiDayEvent() {
        let events: [SimpleWeekEvent] = [
            // Со среды 10:00 до пятницы 15:00
            SimpleWeekEvent(title: "Conference", start: makeDate(dayOffset: 2, hour: 10), end: makeDate(dayOffset: 4, hour: 15), color: .systemPurple),
            // Обычное событие в понедельник
            SimpleWeekEvent(title: "Standup", start: makeDate(dayOffset: 0, hour: 9), end: makeDate(dayOffset: 0, hour: 9, minute: 30), color: .systemBlue),
        ]

        let view = makeWeekView(events: events)
        assertSnapshot(of: view, as: .image)
    }
}

// MARK: - Тестовая модель

struct SimpleWeekEvent: IScheduleEvent {
    let title: String
    let start: Date
    let end: Date
    let color: UIColor
}
