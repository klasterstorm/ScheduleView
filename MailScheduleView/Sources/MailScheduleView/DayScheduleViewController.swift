//
//  DayScheduleViewController.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

/// Контроллер дневного расписания. Отображает один день через DayScheduleView.
public final class DayScheduleViewController: UIViewController, IScheduleViewController {

    // MARK: - IScheduleViewController

    public let dateRange: ScheduleDateRange

    public func showEvents(events: [CalendarEvent]) {
        dayView.events = events
    }

    public func showAllDayEvents(events: [CalendarEvent]) {
        // TODO: секция all-day событий
    }

    // MARK: - Public

    /// Фабрика view для события
    public var viewForEvent: ((CalendarEvent) -> UIView)? {
        didSet { dayView.viewForEvent = viewForEvent }
    }

    /// Вызывается при нажатии на событие
    public var onEventTapped: ((CalendarEvent) -> Void)? {
        didSet { dayView.onEventTapped = onEventTapped }
    }

    /// Конфигурация расписания
    public var config: ScheduleConfig {
        get { dayView.config }
        set { dayView.config = newValue }
    }

    /// Конфигурация таймлайна
    public var timelineConfig: TimelineConfig {
        get { dayView.timelineConfig }
        set { dayView.timelineConfig = newValue }
    }

    // MARK: - Internal

    let dayView = DayScheduleView<CalendarEvent>()
    let scrollView = UIScrollView()

    // MARK: - Init

    /// - Parameter date: дата дня для отображения
    public init(date: Date, calendar: Calendar = .current) {
        let startOfDay = calendar.startOfDay(for: date)
        var endComponents = DateComponents()
        endComponents.hour = 23
        endComponents.minute = 59
        let endOfDay = calendar.date(byAdding: endComponents, to: startOfDay)!
        self.dateRange = ScheduleDateRange(startDate: startOfDay, endDate: endOfDay)
        super.init(nibName: nil, bundle: nil)
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

        dayView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(dayView)
        NSLayoutConstraint.activate([
            dayView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            dayView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            dayView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            dayView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            dayView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            dayView.heightAnchor.constraint(equalToConstant: dayView.config.timelineHeight),
        ])
    }
}
