import UIKit

/// Управляет таймером текущего времени и автоскроллом.
///
/// Извлекает общую логику из `DayScheduleViewController` и `WeekScheduleViewController`:
/// периодическое обновление индикатора текущего времени и однократный скролл к текущей позиции.
final class CurrentTimeTracker {

    /// Провайдер текущей даты (для тестируемости).
    var currentDateProvider: () -> Date = { Date() }

    /// Вызывается при обновлении времени с количеством минут от полуночи.
    var onTimeUpdate: ((CGFloat) -> Void)?

    // MARK: - Private

    private var timer: Timer?

    // MARK: - Tracking

    /// Запускает таймер обновления (60 сек) и немедленно обновляет время.
    func startTracking() {
        updateCurrentTime()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
    }

    /// Останавливает таймер.
    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Scroll

    /// Скроллит к текущему времени (по центру видимой области).
    /// - Parameters:
    ///   - scrollView: scroll view для скролла
    ///   - minuteHeight: высота одной минуты в поинтах
    ///   - animated: анимировать ли скролл
    func scrollToCurrentTime(in scrollView: UIScrollView, minuteHeight: CGFloat, animated: Bool) {
        let minutes = currentMinutesSinceMidnight()
        let y = minutes * minuteHeight
        let visibleHeight = scrollView.bounds.height
        let targetY = max(0, min(y - visibleHeight / 2, scrollView.contentSize.height - visibleHeight))
        scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: animated)
    }

    // MARK: - Private

    private func updateCurrentTime() {
        let minutes = currentMinutesSinceMidnight()
        onTimeUpdate?(minutes)
    }

    private func currentMinutesSinceMidnight() -> CGFloat {
        let date = currentDateProvider()
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return CGFloat((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
    }
}
