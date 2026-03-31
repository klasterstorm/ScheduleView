//
//  DayScheduleViewController.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

/// Контроллер дневного расписания.
///
/// Отображает один день через `DayScheduleView`, обёрнутый в `UIScrollView`.
/// Автоматически показывает индикатор текущего времени и скроллит к нему при первом открытии.
public final class DayScheduleViewController: UIViewController, IScheduleViewController {

    // MARK: - IScheduleViewController

    public let dateRange: ScheduleDateRange

    public func showEvents(
        events: [IScheduleEvent],
        viewForEvent: @escaping (IScheduleEvent) -> UIView,
        onEventTapped: ((IScheduleEvent) -> Void)?
    ) {
        dayView.viewForEvent = { anyEvent in viewForEvent(anyEvent.wrapped) }
        dayView.onEventTapped = onEventTapped.map { handler in
            { anyEvent in handler(anyEvent.wrapped) }
        }
        dayView.events = events.map { AnyScheduleEvent($0) }
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
        get { dayView.config }
        set { dayView.config = newValue }
    }

    /// Конфигурация таймлайна
    public var timelineConfig: TimelineConfig {
        get { dayView.timelineConfig }
        set { dayView.timelineConfig = newValue }
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

    let dayView = DayScheduleView<AnyScheduleEvent>()
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

    /// - Parameter date: дата дня для отображения
    public init(date: Date, calendar: Calendar = .current) {
        let startOfDay = calendar.startOfDay(for: date)
        var endComponents = DateComponents()
        endComponents.hour = 23
        endComponents.minute = 59
        let endOfDay = calendar.date(byAdding: endComponents, to: startOfDay)!
        self.dateRange = ScheduleDateRange(startDate: startOfDay, endDate: endOfDay)
        super.init(nibName: nil, bundle: nil)

        timeTracker.onTimeUpdate = { [weak self] minutes in
            self?.dayView.setCurrentTime(minutesSinceMidnight: minutes)
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
