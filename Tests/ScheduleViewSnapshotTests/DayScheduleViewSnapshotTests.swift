import XCTest
import SnapshotTesting
@testable import ScheduleView

final class DayScheduleViewSnapshotTests: XCTestCase {

    // При первом запуске тестов эталонные снимки создаются автоматически.
    // Повторный запуск сравнивает с эталоном.
    // Чтобы перезаписать эталоны: isRecording = true

    override func setUp() {
        super.setUp()
        // isRecording = true
    }

    // MARK: - Helpers

    private func makeDate(hour: Int, minute: Int = 0) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
    }

    private func makeScheduleView(
        events: [SimpleEvent],
        hourHeight: CGFloat = 60
    ) -> DayScheduleView<SimpleEvent> {
        let config = ScheduleConfig(hourHeight: hourHeight)
        let totalHeight = config.timelineHeight
        let view = DayScheduleView<SimpleEvent>(frame: CGRect(x: 0, y: 0, width: 375, height: totalHeight))
        view.config = config
        view.backgroundColor = .systemBackground
        view.viewForEvent = { event in
            let v = UIView()
            v.backgroundColor = event.color.withAlphaComponent(0.85)
            v.layer.cornerRadius = 6
            v.clipsToBounds = true

            let label = UILabel()
            label.text = event.title
            label.font = .systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: v.topAnchor, constant: 4),
                label.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 4),
                label.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -4),
            ])
            return v
        }
        view.events = events
        view.layoutIfNeeded()
        return view
    }

    // MARK: - Одно событие

    func testSingleEvent() {
        let view = makeScheduleView(events: [
            SimpleEvent(title: "Standup", start: makeDate(hour: 9), end: makeDate(hour: 10), color: .systemBlue),
        ])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Два пересекающихся события

    func testTwoOverlappingEvents() {
        let view = makeScheduleView(events: [
            SimpleEvent(title: "Meeting A", start: makeDate(hour: 9), end: makeDate(hour: 10, minute: 30), color: .systemBlue),
            SimpleEvent(title: "Meeting B", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 11), color: .systemGreen),
        ])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Три пересекающихся события

    func testThreeOverlappingEvents() {
        let view = makeScheduleView(events: [
            SimpleEvent(title: "A", start: makeDate(hour: 9), end: makeDate(hour: 10, minute: 30), color: .systemBlue),
            SimpleEvent(title: "B", start: makeDate(hour: 9, minute: 15), end: makeDate(hour: 10, minute: 15), color: .systemGreen),
            SimpleEvent(title: "C", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10), color: .systemPurple),
        ])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Смешанный день: пересечения + одиночные

    func testMixedDay() {
        let view = makeScheduleView(events: [
            SimpleEvent(title: "Standup", start: makeDate(hour: 9), end: makeDate(hour: 9, minute: 30), color: .systemBlue),
            SimpleEvent(title: "Design Review", start: makeDate(hour: 9, minute: 15), end: makeDate(hour: 10, minute: 15), color: .systemGreen),
            SimpleEvent(title: "1:1", start: makeDate(hour: 9, minute: 30), end: makeDate(hour: 10), color: .systemPurple),
            SimpleEvent(title: "Lunch", start: makeDate(hour: 12), end: makeDate(hour: 13), color: .systemOrange),
            SimpleEvent(title: "Code Review", start: makeDate(hour: 14), end: makeDate(hour: 15), color: .systemRed),
            SimpleEvent(title: "Planning", start: makeDate(hour: 14, minute: 30), end: makeDate(hour: 15, minute: 30), color: .systemTeal),
        ])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Пустой день

    func testEmptyDay() {
        let view = makeScheduleView(events: [])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Короткое событие (минимальная высота)

    func testShortEvent() {
        let view = makeScheduleView(events: [
            SimpleEvent(title: "Quick sync", start: makeDate(hour: 10), end: makeDate(hour: 10, minute: 10), color: .systemIndigo),
        ])
        assertSnapshot(of: view, as: .image)
    }

    // MARK: - Кастомный viewForEvent не задан (дефолтный вид)

    func testDefaultEventAppearance() {
        let config = ScheduleConfig(hourHeight: 60)
        let view = DayScheduleView<SimpleEvent>(frame: CGRect(x: 0, y: 0, width: 375, height: config.timelineHeight))
        view.config = config
        view.backgroundColor = .systemBackground
        // viewForEvent НЕ задан — используется дефолтный синий блок
        view.events = [
            SimpleEvent(title: "Event", start: makeDate(hour: 10), end: makeDate(hour: 11), color: .red),
        ]
        view.layoutIfNeeded()
        assertSnapshot(of: view, as: .image)
    }
    // MARK: - Разные длительности событий

    func testVariousEventDurations() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let base = cal.date(bySettingHour: 9, minute: 0, second: 0, of: today)!

        let events: [SimpleEvent] = [
            SimpleEvent(title: "5 сек (09:00–09:00)", start: base,
                        end: base.addingTimeInterval(5), color: .systemRed),
            SimpleEvent(title: "1 мин (09:10–09:11)", start: base.addingTimeInterval(10 * 60),
                        end: base.addingTimeInterval(11 * 60), color: .systemOrange),
            SimpleEvent(title: "5 мин (09:20–09:25)", start: base.addingTimeInterval(20 * 60),
                        end: base.addingTimeInterval(25 * 60), color: .systemYellow),
            SimpleEvent(title: "10 мин (09:35–09:45)", start: base.addingTimeInterval(35 * 60),
                        end: base.addingTimeInterval(45 * 60), color: .systemGreen),
            SimpleEvent(title: "15 мин (09:55–10:10)", start: base.addingTimeInterval(55 * 60),
                        end: base.addingTimeInterval(70 * 60), color: .systemTeal),
            SimpleEvent(title: "30 мин (10:20–10:50)", start: base.addingTimeInterval(80 * 60),
                        end: base.addingTimeInterval(110 * 60), color: .systemBlue),
            SimpleEvent(title: "1 час (11:00–12:00)", start: base.addingTimeInterval(120 * 60),
                        end: base.addingTimeInterval(180 * 60), color: .systemPurple),
        ]

        let view = makeScheduleView(events: events)
        assertSnapshot(of: view, as: .image)
    }
    // MARK: - Короткие события подряд без пересечения по времени

    func testShortEventsNoTimeOverlap() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let base = cal.date(bySettingHour: 9, minute: 0, second: 0, of: today)!

        // События идут подряд без пересечения по времени,
        // но из-за минимальной высоты визуально должны были бы наложиться
        let events: [SimpleEvent] = [
            SimpleEvent(title: "5 сек (09:00:00–09:00:05)", start: base,
                        end: base.addingTimeInterval(5), color: .systemRed),
            SimpleEvent(title: "5 сек (09:00:05–09:00:10)", start: base.addingTimeInterval(5),
                        end: base.addingTimeInterval(10), color: .systemOrange),
            SimpleEvent(title: "5 сек (09:00:10–09:00:15)", start: base.addingTimeInterval(10),
                        end: base.addingTimeInterval(15), color: .systemYellow),
            SimpleEvent(title: "1 мин (09:01–09:02)", start: base.addingTimeInterval(60),
                        end: base.addingTimeInterval(120), color: .systemGreen),
            SimpleEvent(title: "1 мин (09:02–09:03)", start: base.addingTimeInterval(120),
                        end: base.addingTimeInterval(180), color: .systemTeal),
            SimpleEvent(title: "2 мин (09:03–09:05)", start: base.addingTimeInterval(180),
                        end: base.addingTimeInterval(300), color: .systemBlue),
            SimpleEvent(title: "5 мин (09:05–09:10)", start: base.addingTimeInterval(300),
                        end: base.addingTimeInterval(600), color: .systemPurple),
        ]

        let view = makeScheduleView(events: events)
        assertSnapshot(of: view, as: .image)
    }
    // MARK: - Короткие события визуально пересекаются → разные колонки

    func testShortEventsVisualOverlapColumns() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let base = cal.date(bySettingHour: 10, minute: 0, second: 0, of: today)!

        // Три события по 5 секунд подряд — по времени НЕ пересекаются,
        // но минимальная высота (20pt = 20 мин при hourHeight=60)
        // делает их визуально пересекающимися → должны разойтись по колонкам
        let events: [SimpleEvent] = [
            SimpleEvent(title: "A (10:00:00–10:00:05)", start: base,
                        end: base.addingTimeInterval(5), color: .systemRed),
            SimpleEvent(title: "B (10:00:05–10:00:10)", start: base.addingTimeInterval(5),
                        end: base.addingTimeInterval(10), color: .systemGreen),
            SimpleEvent(title: "C (10:00:10–10:00:15)", start: base.addingTimeInterval(10),
                        end: base.addingTimeInterval(15), color: .systemBlue),
            // Это событие далеко — должно быть в одной колонке
            SimpleEvent(title: "D (11:00–11:30)", start: base.addingTimeInterval(60 * 60),
                        end: base.addingTimeInterval(90 * 60), color: .systemOrange),
        ]

        let view = makeScheduleView(events: events)
        assertSnapshot(of: view, as: .image)
    }
}

// MARK: - Тестовая модель с визуальными свойствами

struct SimpleEvent: IScheduleEvent {
    let title: String
    let start: Date
    let end: Date
    let color: UIColor
}
