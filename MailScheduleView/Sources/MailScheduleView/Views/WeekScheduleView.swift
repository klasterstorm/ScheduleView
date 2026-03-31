import UIKit

/// Недельное расписание — 7 колонок (дней) с общей временной шкалой.
///
/// Внутри использует 7 экземпляров `DayScheduleView` (без таймлайна),
/// объединённых через UIStackView. Общая временная шкала слева.
///
/// ```
/// let week = WeekScheduleView<EASEvent>()
/// week.config = ScheduleConfig(hourHeight: 60, minEventHeight: 20)
/// week.startOfWeek = mondayDate
/// week.viewForEvent = { event in ... }
/// week.onEventTapped = { event in ... }
/// week.events = allEvents // передайте все события, фильтрация по дням автоматическая
/// ```
/// Оберните в UIScrollView для вертикальной прокрутки.
public final class WeekScheduleView<Event: IScheduleEvent>: UIView {

    // MARK: - Public

    /// Конфигурация расписания
    public var config = ScheduleConfig() {
        didSet { setNeedsReload() }
    }

    /// Конфигурация таймлайна
    public var timelineConfig = TimelineConfig() {
        didSet { setNeedsReload() }
    }

    /// Первый день отображаемой недели (обычно понедельник)
    public var startOfWeek: Date = Calendar.current.startOfDay(for: Date()) {
        didSet { setNeedsReload() }
    }

    /// Часовой пояс для разбивки событий по дням
    public var timeZone: TimeZone = .current {
        didSet {
            resolver.timeZone = timeZone
            setNeedsReload()
        }
    }

    /// Фабрика view для события
    public var viewForEvent: ((Event) -> UIView)?

    /// Вызывается при нажатии на событие
    public var onEventTapped: ((Event) -> Void)?

    /// События для отображения (все, за любой период — фильтрация автоматическая)
    public var events: [Event] = [] {
        didSet { reload() }
    }

    // MARK: - Private

    private let resolver: EventDayResolver<Event>
    private let timelineView = TimelineView()
    private let currentTimeIndicator = CurrentTimeIndicatorView()
    private var currentMinutes: CGFloat = 0
    private var hasCurrentTime = false
    private let dayColumnsStack = UIStackView()
    private var dayColumnSeparators: [UIView] = []
    private var dayViews: [DayScheduleView<DaySlice<Event>>] = []
    private var needsReload = false

    // MARK: - Init

    /// - Parameter resolver: резолвер для разбивки событий по дням (инъекция зависимости)
    public init(resolver: EventDayResolver<Event> = EventDayResolver<Event>(), frame: CGRect = .zero) {
        self.resolver = resolver
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.resolver = EventDayResolver<Event>()
        super.init(coder: coder)
        setup()
    }

    // MARK: - Intrinsic size

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: config.timelineHeight)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        if needsReload {
            needsReload = false
            reload()
        }
        timelineView.frame = bounds
        timelineView.layoutTimeline(config: config, timelineConfig: timelineConfig, totalWidth: bounds.width)
        dayColumnsStack.frame = CGRect(
            x: timelineConfig.eventsLeft, y: 0,
            width: bounds.width - timelineConfig.eventsLeft, height: bounds.height
        )
        layoutSeparators()
        layoutCurrentTimeIndicator()
    }

    // MARK: - Current time indicator

    /// Устанавливает текущее время для индикатора.
    /// Вызывается контроллером через `CurrentTimeTracker`.
    /// - Parameter minutesSinceMidnight: минуты от полуночи (0–1439)
    internal func setCurrentTime(minutesSinceMidnight: CGFloat) {
        currentMinutes = minutesSinceMidnight
        hasCurrentTime = true
        setNeedsLayout()
    }

    private func layoutCurrentTimeIndicator() {
        let indicatorConfig = config.currentTimeIndicator
        let shouldShow = hasCurrentTime && !indicatorConfig.isHidden
        currentTimeIndicator.isHidden = !shouldShow
        guard shouldShow else { return }

        let y = currentMinutes * config.minuteHeight
        let r = indicatorConfig.circleRadius
        let diameter = r * 2

        currentTimeIndicator.configure(config: indicatorConfig)
        currentTimeIndicator.frame = CGRect(
            x: timelineConfig.eventsLeft - diameter,
            y: y - r,
            width: bounds.width - timelineConfig.eventsLeft + diameter,
            height: diameter
        )
        currentTimeIndicator.layoutIndicator(
            lineLeft: diameter,
            lineWidth: bounds.width - timelineConfig.eventsLeft
        )
        bringSubviewToFront(currentTimeIndicator)
    }

    // MARK: - Setup

    private func setup() {
        addSubview(timelineView)
        addSubview(currentTimeIndicator)

        for _ in 0..<7 {
            let sep = UIView()
            sep.backgroundColor = UIColor.separator
            addSubview(sep)
            dayColumnSeparators.append(sep)
        }

        dayColumnsStack.axis = .horizontal
        dayColumnsStack.distribution = .fillEqually
        addSubview(dayColumnsStack)

        for _ in 0..<7 {
            let dayView = DayScheduleView<DaySlice<Event>>()
            dayView.displayMode = .embedded
            dayView.clipsToBounds = true
            dayColumnsStack.addArrangedSubview(dayView)
            dayViews.append(dayView)
        }
    }

    private func setNeedsReload() {
        needsReload = true
        setNeedsLayout()
    }

    // MARK: - Separators layout

    private func layoutSeparators() {
        let eventsWidth = bounds.width - timelineConfig.eventsLeft
        let dayWidth = eventsWidth / 7.0

        for i in 0..<7 {
            let x = timelineConfig.eventsLeft + CGFloat(i) * dayWidth
            dayColumnSeparators[i].frame = CGRect(x: x, y: 0, width: 0.5, height: bounds.height)
        }
    }

    // MARK: - Events

    private func reload() {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        resolver.timeZone = timeZone

        for dayIndex in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek) else {
                dayViews[dayIndex].events = []
                continue
            }

            let slices = resolver.resolve(events: events, for: date)

            dayViews[dayIndex].config = config
            dayViews[dayIndex].calendar = calendar

            if let factory = self.viewForEvent {
                dayViews[dayIndex].viewForEvent = { slice in factory(slice.original) }
            } else {
                dayViews[dayIndex].viewForEvent = nil
            }

            dayViews[dayIndex].onEventTapped = { [weak self] slice in
                self?.onEventTapped?(slice.original)
            }

            dayViews[dayIndex].events = slices
        }

        setNeedsLayout()
    }
}
