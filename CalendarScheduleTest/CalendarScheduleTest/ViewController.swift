import UIKit
import MailScheduleView

class ViewController: UIViewController, ICalendarSchedulePageControllerDelegate {

    // MARK: - UI

    let pageView = CalendarSchedulePageView(initialDate: Date())
    let dateStrip = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    // MARK: - Дата-стрип: состояние

    let daysRange = 121
    let centerIndex = 60
    var baseDate: Date = Calendar.current.startOfDay(for: Date())
    var selectedIndex: Int = 60
    private var didInitialScroll = false

    // MARK: - Данные

    private var testEvents: [ExampleCalendarEvent] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Расписание"

        setupSegmentedControl()
        setupDateStrip()
        setupPageView()
        testEvents = TestEventGenerator.generate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didInitialScroll {
            didInitialScroll = true
            scrollStripToIndex(selectedIndex, animated: false)
        }
    }

    // MARK: - Setup

    private func setupSegmentedControl() {
        let control = UISegmentedControl(items: ["День", "Неделя", "Месяц"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
        navigationItem.titleView = control
    }

    private func setupDateStrip() {
        let layout = dateStrip.collectionViewLayout as! UICollectionViewFlowLayout
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 52, height: 60)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        dateStrip.backgroundColor = .systemBackground
        dateStrip.showsHorizontalScrollIndicator = false
        dateStrip.register(DateCell.self, forCellWithReuseIdentifier: DateCell.id)
        dateStrip.dataSource = self
        dateStrip.delegate = self

        dateStrip.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateStrip)
        NSLayoutConstraint.activate([
            dateStrip.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dateStrip.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dateStrip.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dateStrip.heightAnchor.constraint(equalToConstant: 68),
        ])
    }

    private func setupPageView() {
        pageView.delegate = self
        pageView.config = ScheduleConfig(hourHeight: 60, minEventHeight: 20)
        pageView.viewForEvent = { event in
            let label = UILabel()
            label.text = " \(event.title)"
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .white
            label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.85)
            label.layer.cornerRadius = 4
            label.clipsToBounds = true
            return label
        }

        pageView.onDateChanged = { [weak self] date in
            self?.syncStripToDate(date)
        }

        pageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView)
        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: dateStrip.bottomAnchor),
            pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        pageView.scroll(to: Date())
    }

    // MARK: - ICalendarSchedulePageControllerDelegate

    func eventsRequested(for schedule: IScheduleViewController) {
        let range = schedule.dateRange
        let filtered = testEvents.filter { $0.startDate < range.endDate && $0.endDate > range.startDate }
        schedule.showEvents(events: filtered)
    }

    // MARK: - Actions

    @objc private func displayModeChanged(_ sender: UISegmentedControl) {
        let modes: [ScheduleDisplayMode] = [.day, .week, .month]
        pageView.displayMode = modes[sender.selectedSegmentIndex]
    }
}
