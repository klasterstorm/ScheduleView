//
//  ViewController.swift
//  CalendarScheduleTest
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit
import MailScheduleView

class ViewController: UIViewController, ICalendarSchedulePageControllerDelegate {

    private let pageView = CalendarSchedulePageView(initialDate: Date())
    private let segmentedControl = UISegmentedControl(items: ["День", "Неделя", "Месяц"])
    private let dateStrip = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    /// Количество дней в стрипе (±60 от сегодня)
    private let daysRange = 121
    private let centerIndex = 60
    private var baseDate: Date = Calendar.current.startOfDay(for: Date())
    private var selectedIndex: Int = 60

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Расписание"

        setupSegmentedControl()
        setupDateStrip()
        setupPageView()
        generateTestEvents()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Скроллим к выбранной дате после первого layout
        if !didInitialScroll {
            didInitialScroll = true
            scrollStripToIndex(selectedIndex, animated: false)
        }
    }

    private var didInitialScroll = false

    // MARK: - Setup

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
        navigationItem.titleView = segmentedControl
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

    // MARK: - Дата-стрип

    private func date(at index: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: index - centerIndex, to: baseDate)!
    }

    private func index(for date: Date) -> Int? {
        let day = Calendar.current.startOfDay(for: date)
        let diff = Calendar.current.dateComponents([.day], from: baseDate, to: day).day ?? 0
        let idx = centerIndex + diff
        return (0..<daysRange).contains(idx) ? idx : nil
    }

    private func syncStripToDate(_ date: Date) {
        guard let idx = index(for: date) else { return }
        let oldIndex = selectedIndex
        selectedIndex = idx

        var indexPaths = [IndexPath(item: idx, section: 0)]
        if oldIndex != idx {
            indexPaths.append(IndexPath(item: oldIndex, section: 0))
        }
        dateStrip.reloadItems(at: indexPaths)
        scrollStripToIndex(idx, animated: true)
    }

    private func scrollStripToIndex(_ index: Int, animated: Bool) {
        dateStrip.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
    }

    // MARK: - Тестовые события

    private var testEvents: [CalendarEvent] = []

    private func generateTestEvents() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        for dayOffset in -7...7 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = cal.component(.weekday, from: day) // 1=вс, 7=сб

            // Стендап каждый будний день
            if (2...6).contains(weekday) {
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 9, minute: 30), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 9, minute: 45), to: day)!,
                    title: "Стендап"
                ))
            }

            // Обед каждый день
            testEvents.append(CalendarEvent(
                startDate: cal.date(byAdding: DateComponents(hour: 12, minute: 30), to: day)!,
                endDate: cal.date(byAdding: DateComponents(hour: 13, minute: 30), to: day)!,
                title: "Обед"
            ))

            // Разные события в зависимости от дня
            switch dayOffset {
            case -7:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 11, minute: 30), to: day)!,
                    title: "Планирование спринта"
                ))
            case -6:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 14), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 15), to: day)!,
                    title: "1-on-1 с тимлидом"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 16), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 17, minute: 30), to: day)!,
                    title: "Архитектурный ревью"
                ))
            case -5:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 11), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 12), to: day)!,
                    title: "Демо заказчику"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 15), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 15, minute: 30), to: day)!,
                    title: "Код-ревью: PR #142"
                ))
            case -4:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 10, minute: 30), to: day)!,
                    title: "Собеседование (скрининг)"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 14), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 16), to: day)!,
                    title: "Хакатон: прототип"
                ))
            case -3:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 8), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 8, minute: 30), to: day)!,
                    title: "Зарядка"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 15), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 16, minute: 30), to: day)!,
                    title: "Ретроспектива"
                ))
            case -2, -1:
                // Выходные — минимум событий
                break
            case 0:
                // Сегодня — насыщенный день
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 11), to: day)!,
                    title: "Груминг бэклога"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 11), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 11, minute: 45), to: day)!,
                    title: "Синк с бэкендом"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 14), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 15), to: day)!,
                    title: "Код-ревью: PR #158"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 16), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 17), to: day)!,
                    title: "Тех.долг: рефакторинг"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 17, minute: 30), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 18), to: day)!,
                    title: "Английский с репетитором"
                ))
            case 1:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 12), to: day)!,
                    title: "Воркшоп: SwiftUI"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 14, minute: 30), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 15, minute: 30), to: day)!,
                    title: "Менторинг джуна"
                ))
            case 2:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 11), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 11, minute: 30), to: day)!,
                    title: "Дизайн-ревью"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 15), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 16), to: day)!,
                    title: "1-on-1 с тимлидом"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 16), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 16, minute: 30), to: day)!,
                    title: "Собеседование (тех.)"
                ))
            case 3:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 11, minute: 30), to: day)!,
                    title: "Планирование спринта"
                ))
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 14), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 14, minute: 30), to: day)!,
                    title: "Релиз-чеклист"
                ))
            case 4:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 11), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 12, minute: 15), to: day)!,
                    title: "Демо заказчику"
                ))
            case 5, 6:
                // Выходные
                if dayOffset == 6 {
                    testEvents.append(CalendarEvent(
                        startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                        endDate: cal.date(byAdding: DateComponents(hour: 11, minute: 30), to: day)!,
                        title: "Бег в парке"
                    ))
                }
            default:
                testEvents.append(CalendarEvent(
                    startDate: cal.date(byAdding: DateComponents(hour: 10), to: day)!,
                    endDate: cal.date(byAdding: DateComponents(hour: 11), to: day)!,
                    title: "Встреча"
                ))
            }
        }
    }

    // MARK: - ICalendarSchedulePageControllerDelegate

    func eventsRequested(for schedule: IScheduleViewController) {
        let range = schedule.dateRange
        let filtered = testEvents.filter { event in
            event.startDate < range.endDate && event.endDate > range.startDate
        }
        schedule.showEvents(events: filtered)
    }

    // MARK: - Actions

    @objc private func displayModeChanged() {
        let modes: [ScheduleDisplayMode] = [.day, .week, .month]
        pageView.displayMode = modes[segmentedControl.selectedSegmentIndex]
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        daysRange
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateCell.id, for: indexPath) as! DateCell
        let cellDate = date(at: indexPath.item)
        let isSelected = indexPath.item == selectedIndex
        let isToday = Calendar.current.isDateInToday(cellDate)
        cell.configure(date: cellDate, isSelected: isSelected, isToday: isToday)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tappedDate = date(at: indexPath.item)
        let oldIndex = selectedIndex
        selectedIndex = indexPath.item

        var indexPaths = [indexPath]
        if oldIndex != indexPath.item {
            indexPaths.append(IndexPath(item: oldIndex, section: 0))
        }
        dateStrip.reloadItems(at: indexPaths)
        scrollStripToIndex(indexPath.item, animated: true)
        pageView.scroll(to: tappedDate)
    }
}

// MARK: - DateCell

private final class DateCell: UICollectionViewCell {

    static let id = "DateCell"

    private let weekdayLabel = UILabel()
    private let dayLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        weekdayLabel.font = .systemFont(ofSize: 11, weight: .medium)
        weekdayLabel.textAlignment = .center

        dayLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        dayLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [weekdayLabel, dayLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(date: Date, isSelected: Bool, isToday: Bool) {
        let cal = Calendar.current
        let day = cal.component(.day, from: date)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        let weekday = formatter.string(from: date).capitalized

        weekdayLabel.text = weekday
        dayLabel.text = "\(day)"

        if isSelected {
            contentView.backgroundColor = .systemBlue
            weekdayLabel.textColor = .white
            dayLabel.textColor = .white
        } else if isToday {
            contentView.backgroundColor = .systemBlue.withAlphaComponent(0.15)
            weekdayLabel.textColor = .systemBlue
            dayLabel.textColor = .systemBlue
        } else {
            contentView.backgroundColor = .clear
            weekdayLabel.textColor = .secondaryLabel
            dayLabel.textColor = .label
        }
    }
}
