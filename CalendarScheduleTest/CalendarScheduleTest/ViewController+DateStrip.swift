import UIKit
import MailScheduleView

// MARK: - Дата-стрип: навигация и синхронизация

extension ViewController {

    func date(at index: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: index - centerIndex, to: baseDate)!
    }

    func index(for date: Date) -> Int? {
        let day = Calendar.current.startOfDay(for: date)
        let diff = Calendar.current.dateComponents([.day], from: baseDate, to: day).day ?? 0
        let idx = centerIndex + diff
        return (0..<daysRange).contains(idx) ? idx : nil
    }

    func syncStripToDate(_ date: Date) {
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

    func scrollStripToIndex(_ index: Int, animated: Bool) {
        dateStrip.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
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
