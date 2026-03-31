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
        saveScrollOffset()
        let vc = makeViewController(for: date)
        pageViewController.setViewControllers([vc], direction: .forward, animated: false)
        currentDate = date
        delegate?.eventsRequested(for: vc)
    }

    // MARK: - Public

    /// Скроллит текущую страницу расписания к текущему времени.
    public func scrollToCurrentTime(animated: Bool = false) {
        guard let vc = pageViewController.viewControllers?.first as? IScheduleViewController else { return }
        vc.scrollToCurrentTime(animated: animated)
    }

    /// Режим отображения: день, неделя или месяц
    public var displayMode: ScheduleDisplayMode = .day {
        didSet {
            guard oldValue != displayMode else { return }
            scroll(to: currentDate)
        }
    }

    /// Конфигурация расписания
    public var config = ScheduleConfig()

    /// Вызывается при смене текущей даты (свайп или scroll(to:))
    public var onDateChanged: ((Date) -> Void)?

    /// Конфигурация таймлайна
    public var timelineConfig = TimelineConfig()

    // MARK: - Internal (доступно для тестирования через @testable import)

    let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    /// Текущая отображаемая дата
    var currentDate: Date

    /// Календарь для расчёта дат
    private var calendar: Calendar = .current

    /// Сохранённая позиция скролла (`nil` = первый показ → scrollToCurrentTime)
    private var savedScrollOffsetY: CGFloat?

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

    private func makeViewController(for date: Date) -> IScheduleViewController {
        let vc: IScheduleViewController
        switch displayMode {
        case .day:
            vc = DayScheduleViewController(date: date, calendar: calendar)
        case .week:
            let start = startOfWeek(for: date)
            vc = WeekScheduleViewController(startOfWeek: start, calendar: calendar)
        case .month:
            vc = MonthScheduleViewController(date: date, calendar: calendar)
        }
        configureViewController(vc)
        return vc
    }

    /// Пробрасывает конфиг и начальную позицию скролла.
    private func configureViewController(_ vc: IScheduleViewController) {
        if let dayVC = vc as? DayScheduleViewController {
            dayVC.config = config
            dayVC.timelineConfig = timelineConfig
        } else if let weekVC = vc as? WeekScheduleViewController {
            weekVC.config = config
            weekVC.timelineConfig = timelineConfig
        }
        // nil → VC сам скроллит к текущему времени в viewDidLayoutSubviews
        vc.initialScrollOffsetY = savedScrollOffsetY
    }

    /// Сохраняет позицию скролла текущего VC.
    private func saveScrollOffset() {
        guard let vc = pageViewController.viewControllers?.first as? IScheduleViewController else { return }
        savedScrollOffsetY = vc.scrollOffsetY
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
    private func referenceDate(from viewController: UIViewController) -> Date? {
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
        saveScrollOffset()
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
        saveScrollOffset()
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
