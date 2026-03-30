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

    // MARK: - Internal

    /// Режим отображения: standalone (с таймлайном) или embedded (без таймлайна)
    var displayMode: DisplayMode = .standalone

    /// Календарь для расчёта позиций событий
    var calendar: Calendar = .current

    /// Фабрика дефолтного view для событий (подменяемая)
    var defaultViewFactory: (() -> UIView) = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        return view
    }

    // MARK: - Private

    private let timelineView = TimelineView()
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
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(timelineView)
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
