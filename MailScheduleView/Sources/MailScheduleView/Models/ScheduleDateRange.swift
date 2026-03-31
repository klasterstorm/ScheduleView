import Foundation

/// Временной интервал расписания.
///
/// Определяет диапазон дат, покрываемый контроллером расписания.
/// Используется потребителем для запроса событий за нужный период.
public struct ScheduleDateRange {

    /// Начало интервала (включительно)
    public let startDate: Date

    /// Конец интервала (включительно)
    public let endDate: Date

    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}
