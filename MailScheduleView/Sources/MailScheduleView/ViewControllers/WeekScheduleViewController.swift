//
//  WeekScheduleViewController.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

/// Контроллер недельного расписания.
///
/// Отображает одну неделю через `WeekScheduleView`, обёрнутый в `UIScrollView`.
/// Автоматически показывает индикатор текущего времени и скроллит к нему при первом открытии.
public final class WeekScheduleViewController: UIViewController, IScheduleViewController {

    // MARK: - IScheduleViewController

    public let dateRange: ScheduleDateRange

    public func showEvents(
        events: [IScheduleEvent],
        viewForEvent: @escaping (IScheduleEvent) -> UIView,
        onEventTapped: ((IScheduleEvent) -> Void)?
    ) {
        weekView.viewForEvent = { anyEvent in viewForEvent(anyEvent.wrapped) }
        weekView.onEventTapped = onEventTapped.map { handler in
            { anyEvent in handler(anyEvent.wrapped) }
        }
        weekView.events = events.map { AnyScheduleEvent($0) }
    }

    public func showAllDayEvents(
        events: [IScheduleEvent],
        viewForEvent: @escaping (IScheduleEvent) -> UIView,
        onEventTapped: ((IScheduleEvent) -> Void)?
    ) {
        // TODO: секция all-day событий
    }

    // MARK: - Public

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

    /// Скроллит к текущему времени (по центру видимой области).
    public func scrollToCurrentTime(animated: Bool = true) {
        timeTracker.scrollToCurrentTime(in: scrollView, minuteHeight: config.minuteHeight, animated: animated)
    }

    /// Текущая вертикальная позиция скролла.
    public var scrollOffsetY: CGFloat {
        get { scrollView.contentOffset.y }
        set { scrollView.contentOffset.y = newValue }
    }

    /// Начальная позиция скролла. Если `nil` — скроллит к текущему времени.
    public var initialScrollOffsetY: CGFloat?

    // MARK: - Internal (доступно для тестирования через @testable import)

    let weekView = WeekScheduleView<AnyScheduleEvent>()
    let scrollView = UIScrollView()

    /// Провайдер текущей даты — проброс к `timeTracker` (для тестируемости)
    var currentDateProvider: () -> Date {
        get { timeTracker.currentDateProvider }
        set { timeTracker.currentDateProvider = newValue }
    }

    // MARK: - Private

    private let timeTracker = CurrentTimeTracker()
    private var didApplyInitialScroll = false

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

        timeTracker.onTimeUpdate = { [weak self] minutes in
            self?.weekView.setCurrentTime(minutesSinceMidnight: minutes)
        }
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

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didApplyInitialScroll else { return }
        didApplyInitialScroll = true
        if let offset = initialScrollOffsetY {
            scrollView.contentOffset.y = offset
        } else {
            scrollToCurrentTime(animated: false)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timeTracker.startTracking()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timeTracker.stopTracking()
    }
}
