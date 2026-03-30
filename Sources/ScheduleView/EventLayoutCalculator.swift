import UIKit

// MARK: - Layout result

struct EventLayout<Event: IScheduleEvent> {
    let event: Event
    var column: Int
    var totalColumns: Int
}

// MARK: - Overlap algorithm

/// - Parameter minDurationMinutes: минимальная визуальная длительность события в минутах.
///   Используется для корректной кластеризации и назначения колонок,
///   чтобы короткие события с минимальной высотой не налезали друг на друга.
func layoutEvents<Event: IScheduleEvent>(
    _ events: [Event],
    minDurationMinutes: CGFloat = 0,
    calendar: Calendar = .current
) -> [EventLayout<Event>] {
    guard !events.isEmpty else { return [] }

    let sorted = events.sorted { $0.startMinutes(in: calendar) < $1.startMinutes(in: calendar) }

    /// Визуальный конец события с учётом минимальной высоты
    func visualEnd(_ event: Event) -> CGFloat {
        max(event.endMinutes(in: calendar), event.startMinutes(in: calendar) + minDurationMinutes)
    }

    // Фаза 1: кластеризация с учётом визуальной длительности
    var clusters: [[Event]] = []
    var currentCluster: [Event] = []
    var clusterEnd: CGFloat = -1

    for event in sorted {
        if currentCluster.isEmpty || event.startMinutes(in: calendar) < clusterEnd {
            currentCluster.append(event)
            clusterEnd = max(clusterEnd, visualEnd(event))
        } else {
            clusters.append(currentCluster)
            currentCluster = [event]
            clusterEnd = visualEnd(event)
        }
    }
    if !currentCluster.isEmpty {
        clusters.append(currentCluster)
    }

    // Фаза 2: назначение колонок с учётом визуальной длительности
    var results: [EventLayout<Event>] = []

    for cluster in clusters {
        var columns: [[Event]] = []
        var clusterLayouts: [EventLayout<Event>] = []

        for event in cluster {
            var placed = false
            for colIdx in columns.indices {
                if visualEnd(columns[colIdx].last!) <= event.startMinutes(in: calendar) {
                    columns[colIdx].append(event)
                    clusterLayouts.append(EventLayout(event: event, column: colIdx, totalColumns: -1))
                    placed = true
                    break
                }
            }
            if !placed {
                columns.append([event])
                clusterLayouts.append(EventLayout(event: event, column: columns.count - 1, totalColumns: -1))
            }
        }

        let total = columns.count
        for i in clusterLayouts.indices {
            clusterLayouts[i].totalColumns = total
        }
        results.append(contentsOf: clusterLayouts)
    }

    return results
}

// MARK: - Frame calculation

/// Результат расчёта фрейма для одного события
struct EventFrame {
    let index: Int
    var frame: CGRect
}

/// Чистая функция: рассчитывает фреймы событий на основе layout-данных.
/// Включает логику сдвига пересекающихся событий в одной колонке.
func calculateEventFrames<Event: IScheduleEvent>(
    layouts: [EventLayout<Event>],
    containerWidth: CGFloat,
    leftOffset: CGFloat,
    config: ScheduleConfig,
    calendar: Calendar = .current
) -> [EventFrame] {
    let eventsWidth = containerWidth - leftOffset

    var frames: [EventFrame] = []

    for (i, layout) in layouts.enumerated() {
        let columnWidth = eventsWidth / CGFloat(layout.totalColumns)
        let inset: CGFloat = 1
        let x = leftOffset + CGFloat(layout.column) * columnWidth + inset
        let y = layout.event.startMinutes(in: calendar) * config.minuteHeight
        let h = max(
            (layout.event.endMinutes(in: calendar) - layout.event.startMinutes(in: calendar)) * config.minuteHeight,
            config.minEventHeight
        )
        let w = columnWidth - inset * 2

        frames.append(EventFrame(index: i, frame: CGRect(x: x, y: y, width: w, height: h)))
    }

    // Сдвигаем вниз пересекающиеся события в одной колонке
    var columnBottoms: [Int: CGFloat] = [:]
    for i in frames.indices {
        let col = layouts[i].column
        if let prevBottom = columnBottoms[col], frames[i].frame.origin.y < prevBottom {
            frames[i].frame.origin.y = prevBottom
        }
        columnBottoms[col] = frames[i].frame.maxY
    }

    return frames
}
