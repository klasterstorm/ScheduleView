//
//  CalendarSchedulePageView.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

/// UIView, содержащий UIPageViewController для навигации между страницами расписания (день/неделя/месяц).
public final class CalendarSchedulePageView: UIView, ICalendarSchedulePageView {

    // MARK: - ICalendarSchedulePageView

    public weak var delegate: ICalendarSchedulePageControllerDelegate?

    public func scroll(to date: Date) {
        let vc = makeViewController(for: date)
        pageViewController.setViewControllers([vc], direction: .forward, animated: false)
        currentDate = date
        onDateChanged?(date)
        delegate?.eventsRequested(for: vc)
    }

    // MARK: - Public

    /// Режим отображения: день, неделя или месяц
    public var displayMode: ScheduleDisplayMode = .day {
        didSet {
            guard oldValue != displayMode else { return }
            scroll(to: currentDate)
        }
    }

    /// Фабрика view для события — пробрасывается в создаваемые контроллеры
    public var viewForEvent: ((CalendarEvent) -> UIView)?

    /// Вызывается при нажатии на событие
    public var onEventTapped: ((CalendarEvent) -> Void)?

    /// Конфигурация расписания
    public var config = ScheduleConfig()

    /// Вызывается при смене текущей даты (свайп или scroll(to:))
    public var onDateChanged: ((Date) -> Void)?

    /// Конфигурация таймлайна
    public var timelineConfig = TimelineConfig()

    // MARK: - Internal

    let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    /// Текущая отображаемая дата
    var currentDate: Date

    /// Календарь для расчёта дат
    var calendar: Calendar = .current

    // MARK: - Init

    /// - Parameter initialDate: начальная дата для отображения
    public init(initialDate: Date = Date(), frame: CGRect = .zero) {
        self.currentDate = initialDate
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.currentDate = Date()
        super.init(coder: coder)
        setup()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        pageViewController.view.frame = bounds
    }

    // MARK: - Setup

    private func setup() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        addSubview(pageViewController.view)

        let initialVC = makeViewController(for: currentDate)
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
    }

    // MARK: - Фабрика контроллеров

    func makeViewController(for date: Date) -> IScheduleViewController {
        switch displayMode {
        case .day:
            return makeDayViewController(for: date)
        case .week:
            return makeWeekViewController(for: date)
        case .month:
            return makeMonthViewController(for: date)
        }
    }

    private func makeDayViewController(for date: Date) -> DayScheduleViewController {
        let vc = DayScheduleViewController(date: date, calendar: calendar)
        vc.config = config
        vc.timelineConfig = timelineConfig
        vc.viewForEvent = viewForEvent
        vc.onEventTapped = onEventTapped
        return vc
    }

    private func makeWeekViewController(for date: Date) -> WeekScheduleViewController {
        let startOfWeek = self.startOfWeek(for: date)
        let vc = WeekScheduleViewController(startOfWeek: startOfWeek, calendar: calendar)
        vc.config = config
        vc.timelineConfig = timelineConfig
        vc.viewForEvent = viewForEvent
        vc.onEventTapped = onEventTapped
        return vc
    }

    private func makeMonthViewController(for date: Date) -> MonthScheduleViewController {
        return MonthScheduleViewController(date: date, calendar: calendar)
    }

    // MARK: - Навигация по датам

    /// Дата для следующей страницы
    func nextDate(after date: Date) -> Date {
        switch displayMode {
        case .day:
            return calendar.date(byAdding: .day, value: 1, to: date)!
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)!
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: date)!
        }
    }

    /// Дата для предыдущей страницы
    func previousDate(before date: Date) -> Date {
        switch displayMode {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: date)!
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: date)!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: date)!
        }
    }

    /// Начало недели для даты
    private func startOfWeek(for date: Date) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // Понедельник
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date
    }

    /// Извлекает опорную дату из контроллера
    func referenceDate(from viewController: UIViewController) -> Date? {
        guard let scheduleVC = viewController as? IScheduleViewController else { return nil }
        return scheduleVC.dateRange.startDate
    }
}

// MARK: - UIPageViewControllerDataSource

extension CalendarSchedulePageView: UIPageViewControllerDataSource {

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let date = referenceDate(from: viewController) else { return nil }
        let prevDate = previousDate(before: date)
        let vc = makeViewController(for: prevDate)
        delegate?.eventsRequested(for: vc)
        return vc
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let date = referenceDate(from: viewController) else { return nil }
        let nextDate = nextDate(after: date)
        let vc = makeViewController(for: nextDate)
        delegate?.eventsRequested(for: vc)
        return vc
    }
}

// MARK: - UIPageViewControllerDelegate

extension CalendarSchedulePageView: UIPageViewControllerDelegate {

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let date = referenceDate(from: currentVC) else { return }
        currentDate = date
        onDateChanged?(date)
    }
}
