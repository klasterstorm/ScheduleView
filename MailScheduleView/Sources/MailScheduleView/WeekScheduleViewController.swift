//
//  WeekScheduleViewController.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

/// Контроллер недельного расписания. Отображает одну неделю через WeekScheduleView.
public final class WeekScheduleViewController: UIViewController, IScheduleViewController {

    // MARK: - IScheduleViewController

    public let dateRange: ScheduleDateRange

    public func showEvents(events: [CalendarEvent]) {
        weekView.events = events
    }

    public func showAllDayEvents(events: [CalendarEvent]) {
        // TODO: секция all-day событий
    }

    // MARK: - Public

    /// Фабрика view для события
    public var viewForEvent: ((CalendarEvent) -> UIView)? {
        didSet { weekView.viewForEvent = viewForEvent }
    }

    /// Вызывается при нажатии на событие
    public var onEventTapped: ((CalendarEvent) -> Void)? {
        didSet { weekView.onEventTapped = onEventTapped }
    }

    /// Конфигурация расписания
    public var config: ScheduleConfig {
        get { weekView.config }
        set { weekView.config = newValue }
    }

    /// Конфигурация таймлайна
    public var timelineConfig: TimelineConfig {
        get { weekView.timelineConfig }
        set { weekView.timelineConfig = newValue }
    }

    // MARK: - Internal

    let weekView = WeekScheduleView<CalendarEvent>()
    let scrollView = UIScrollView()

    // MARK: - Init

    /// - Parameter startOfWeek: первый день недели (обычно понедельник)
    public init(startOfWeek: Date, calendar: Calendar = .current) {
        let start = calendar.startOfDay(for: startOfWeek)
        let end: Date = {
            // Конец недели: 6 дней + 23:59
            guard let sixthDay = calendar.date(byAdding: .day, value: 6, to: start) else { return start }
            var endComponents = DateComponents()
            endComponents.hour = 23
            endComponents.minute = 59
            return calendar.date(byAdding: endComponents, to: sixthDay) ?? sixthDay
        }()
        self.dateRange = ScheduleDateRange(startDate: start, endDate: end)
        super.init(nibName: nil, bundle: nil)
        weekView.startOfWeek = start
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        weekView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(weekView)
        NSLayoutConstraint.activate([
            weekView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            weekView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            weekView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            weekView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            weekView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            weekView.heightAnchor.constraint(equalToConstant: weekView.config.timelineHeight),
        ])
    }
}
