//
//  IScheduleViewController.swift
//  ScheduleView
//
//  Created by Женя Баян on 30.03.2026.
//

import UIKit

// MARK: - Протокол контроллера расписания

public protocol IScheduleViewController: UIViewController {

    // Временной интервал который покрывает отображение. Если это для одного дня, то будет один день, если расписание на неделю, то будет интервал за неделю
    var dateRange: ScheduleDateRange { get }

    // Метод отображает событий
    func showEvents(events: [CalendarEvent])

    // Метод отображает события на весь день
    func showAllDayEvents(events: [CalendarEvent])
}

// MARK: - Модели

public struct ScheduleDateRange {

    public let startDate: Date

    public let endDate: Date

    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct CalendarEvent: IScheduleEvent {

    public let startDate: Date

    public let endDate: Date

    public let title: String

    public var start: Date { startDate }

    public var end: Date { endDate }

    public init(startDate: Date, endDate: Date, title: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
    }
}

// MARK: - Режим отображения страниц

/// Режим отображения: день, неделя или месяц
public enum ScheduleDisplayMode {
    case day
    case week
    case month
}

// MARK: - Делегат для запроса событий

// Интерфейс которым ICalendarSchedulePageView будет запрашивать события снаружи. Мы делаем универсальный компонент
public protocol ICalendarSchedulePageControllerDelegate: AnyObject {

    // Метод запрашивает события и мапит их методами showEvents и showAllDayEvents. Запрашиваются события по промежутку dateRange
    func eventsRequested(for schedule: IScheduleViewController)
}

// MARK: - Протокол page view

// Тут внутри должен быть UIPageController
public protocol ICalendarSchedulePageView: UIView {

    // Интерфейс которым ICalendarSchedulePageView будет запрашивать события снаружи. Мы делаем универсальный компонент
    var delegate: ICalendarSchedulePageControllerDelegate? { get set }

    // Метод который принудительно скроллит к выбранной дате. При скролле надо вызвать eventsRequested чтобы запросить события
    func scroll(to date: Date)
}
