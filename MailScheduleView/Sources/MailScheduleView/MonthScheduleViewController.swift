//
//  MonthScheduleViewController.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

/// Контроллер месячного расписания (заглушка).
public final class MonthScheduleViewController: UIViewController, IScheduleViewController {

    // MARK: - IScheduleViewController

    public let dateRange: ScheduleDateRange

    public func showEvents(events: [CalendarEvent]) {
        // TODO: реализовать отображение событий в месячном виде
    }

    public func showAllDayEvents(events: [CalendarEvent]) {
        // TODO: реализовать отображение all-day событий
    }

    // MARK: - Init

    /// - Parameter date: любая дата внутри целевого месяца
    public init(date: Date, calendar: Calendar = .current) {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            fatalError("Не удалось определить интервал месяца для \(date)")
        }
        // Конец месяца: последний день 23:59
        let lastSecond = monthInterval.end.addingTimeInterval(-1)
        let startOfLastDay = calendar.startOfDay(for: lastSecond)
        var endComponents = DateComponents()
        endComponents.hour = 23
        endComponents.minute = 59
        let endOfMonth = calendar.date(byAdding: endComponents, to: startOfLastDay) ?? lastSecond

        self.dateRange = ScheduleDateRange(startDate: monthInterval.start, endDate: endOfMonth)
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

        let placeholder = UILabel()
        placeholder.text = "Month View"
        placeholder.textAlignment = .center
        placeholder.textColor = .secondaryLabel
        placeholder.font = .systemFont(ofSize: 24, weight: .medium)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholder)
        NSLayoutConstraint.activate([
            placeholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
