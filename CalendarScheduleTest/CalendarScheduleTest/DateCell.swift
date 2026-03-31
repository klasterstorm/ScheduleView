import UIKit

/// Ячейка горизонтального дата-стрипа: день недели + число.
final class DateCell: UICollectionViewCell {

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
