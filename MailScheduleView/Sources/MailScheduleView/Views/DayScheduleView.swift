import UIKit

/// Режим отображения DayScheduleView
enum DisplayMode {
    /// Самостоятельный вид с таймлайном
    case standalone
    /// Встроенный в WeekScheduleView, без таймлайна
    case embedded
}

/// Generic view дневного расписания.
///
/// Пользователь сам решает, как выглядит событие, через `viewForEvent`:
/// ```
/// let schedule = DayScheduleView<EASEvent>()
/// schedule.config = ScheduleConfig(hourHeight: 60, minEventHeight: 20)
/// schedule.viewForEvent = { easEvent in
///     let v = MyCustomEventView()
///     v.titleLabel.text = easEvent.subject
///     v.backgroundColor = .systemBlue
///     return v
/// }
/// schedule.onEventTapped = { easEvent in ... }
/// schedule.events = easEvents
/// ```
public final class DayScheduleView<Event: IScheduleEvent>: UIView {

    // MARK: - Public

    /// Конфигурация расписания
    public var config = ScheduleConfig() {
        didSet { setNeedsLayout() }
    }

    /// Конфигурация таймлайна (используется в standalone режиме)
    public var timelineConfig = TimelineConfig() {
        didSet { setNeedsLayout() }
    }

    /// Фабрика view для события — аналог cellForRowAt.
    /// Должна быть установлена до присвоения events.
    public var viewForEvent: ((Event) -> UIView)?

    /// Вызывается при нажатии на событие
    public var onEventTapped: ((Event) -> Void)?

    /// События для отображения
    public var events: [Event] = [] {
        didSet { reloadEvents() }
    }

    // MARK: - Internal (доступно для тестирования через @testable import)

    /// Режим отображения: standalone (с таймлайном) или embedded (без таймлайна).
    /// Устанавливается `WeekScheduleView` при создании embedded-колонок.
    internal var displayMode: DisplayMode = .standalone

    /// Календарь для расчёта позиций событий.
    /// Устанавливается `WeekScheduleView` с учётом часового пояса.
    internal var calendar: Calendar = .current

    /// Фабрика дефолтного view для событий (подменяемая в тестах)
    internal var defaultViewFactory: (() -> UIView) = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }

    // MARK: - Private

    private let timelineView = TimelineView()
    private let currentTimeIndicator = CurrentTimeIndicatorView()
    private var currentMinutes: CGFloat = 0
    private var hasCurrentTime = false
    private var eventViews: [UIView] = []
    private var cachedLayouts: [EventLayout<Event>] = []

    /// Левый отступ для событий: eventsLeft в standalone, 0 в embedded
    private var eventsLeftOffset: CGFloat {
        switch displayMode {
        case .standalone: return timelineConfig.eventsLeft
        case .embedded: return 0
        }
    }

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(timelineView)
        addSubview(currentTimeIndicator)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(timelineView)
        addSubview(currentTimeIndicator)
    }

    // MARK: - Intrinsic size

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: config.timelineHeight)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        switch displayMode {
        case .standalone:
            timelineView.isHidden = false
            timelineView.frame = bounds
            timelineView.layoutTimeline(config: config, timelineConfig: timelineConfig, totalWidth: bounds.width)
        case .embedded:
            timelineView.isHidden = true
        }
        layoutEventViews()
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
        let shouldShow = hasCurrentTime && displayMode == .standalone && !indicatorConfig.isHidden
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

    // MARK: - Events

    private func reloadEvents() {
        eventViews.forEach { $0.removeFromSuperview() }
        eventViews.removeAll()

        cachedLayouts = layoutEvents(events, minDurationMinutes: config.minDurationMinutes, calendar: calendar)

        for (index, layout) in cachedLayouts.enumerated() {
            let view = viewForEvent?(layout.event) ?? defaultViewFactory()
            view.tag = index
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(eventTapped(_:)))
            )
            addSubview(view)
            eventViews.append(view)
        }

        setNeedsLayout()
    }

    @objc private func eventTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              view.tag < cachedLayouts.count else { return }
        onEventTapped?(cachedLayouts[view.tag].event)
    }

    private func layoutEventViews() {
        let frames = calculateEventFrames(
            layouts: cachedLayouts,
            containerWidth: bounds.width,
            leftOffset: eventsLeftOffset,
            config: config,
            calendar: calendar
        )

        for info in frames where info.index < eventViews.count {
            eventViews[info.index].frame = info.frame
        }
    }
}
