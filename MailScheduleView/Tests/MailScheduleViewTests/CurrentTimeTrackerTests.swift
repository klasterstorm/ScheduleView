import XCTest
@testable import MailScheduleView

final class CurrentTimeTrackerTests: XCTestCase {

    // MARK: - currentDateProvider используется

    func testUsesCustomDateProvider() {
        let tracker = CurrentTimeTracker()
        tracker.currentDateProvider = { makeDate(day: 25, hour: 14, minute: 30) }

        var receivedMinutes: CGFloat?
        tracker.onTimeUpdate = { minutes in
            receivedMinutes = minutes
        }

        tracker.startTracking()
        defer { tracker.stopTracking() }

        // 14:30 = 870 минут
        XCTAssertEqual(receivedMinutes, 870)
    }

    // MARK: - startTracking вызывает onTimeUpdate немедленно

    func testStartTrackingCallsUpdateImmediately() {
        let tracker = CurrentTimeTracker()
        tracker.currentDateProvider = { makeDate(day: 25, hour: 10, minute: 0) }

        var callCount = 0
        tracker.onTimeUpdate = { _ in
            callCount += 1
        }

        tracker.startTracking()
        defer { tracker.stopTracking() }

        XCTAssertEqual(callCount, 1)
    }

    // MARK: - stopTracking останавливает обновления

    func testStopTrackingInvalidatesTimer() {
        let tracker = CurrentTimeTracker()
        tracker.currentDateProvider = { makeDate(day: 25, hour: 10, minute: 0) }

        tracker.startTracking()
        tracker.stopTracking()

        // Не крашит и не вызывает после остановки
    }

    // MARK: - scrollToCurrentTime

    func testScrollToCurrentTime() {
        let tracker = CurrentTimeTracker()
        tracker.currentDateProvider = { makeDate(day: 25, hour: 14, minute: 0) }

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        scrollView.contentSize = CGSize(width: 320, height: 1440)

        tracker.scrollToCurrentTime(in: scrollView, minuteHeight: 1.0, animated: false)

        // y = 14*60 = 840, center = 840 - 300 = 540
        XCTAssertEqual(scrollView.contentOffset.y, 540, accuracy: 10)
    }

    // MARK: - scrollToCurrentTime клампит к границам

    func testScrollClampsToContentBounds() {
        let tracker = CurrentTimeTracker()
        // 01:00 = 60 минут — слишком рано для центрирования
        tracker.currentDateProvider = { makeDate(day: 25, hour: 1, minute: 0) }

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        scrollView.contentSize = CGSize(width: 320, height: 1440)

        tracker.scrollToCurrentTime(in: scrollView, minuteHeight: 1.0, animated: false)

        // y = 60 - 300 = -240, clamped to 0
        XCTAssertEqual(scrollView.contentOffset.y, 0, accuracy: 1)
    }
}
