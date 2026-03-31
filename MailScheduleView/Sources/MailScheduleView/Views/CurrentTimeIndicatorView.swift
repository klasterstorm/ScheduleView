import UIKit

/// Индикатор текущего времени — горизонтальная линия + круглый маркер слева.
///
/// Родительский view управляет `frame` индикатора. Индикатор
/// позиционирует дочерние элементы только в локальных координатах.
final class CurrentTimeIndicatorView: UIView {

    private let lineView = UIView()
    private let circleView = UIView()
    private var indicatorConfig = CurrentTimeIndicatorConfig()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = false
        clipsToBounds = false
        addSubview(lineView)
        addSubview(circleView)
    }

    // MARK: - Configuration

    /// Применяет визуальные параметры (цвет, размеры).
    /// - Parameter config: параметры индикатора
    func configure(config: CurrentTimeIndicatorConfig) {
        indicatorConfig = config
        circleView.backgroundColor = config.color
        circleView.layer.cornerRadius = config.circleRadius
        lineView.backgroundColor = config.color
    }

    // MARK: - Layout

    /// Раскладывает кружок и линию внутри текущего `frame`.
    ///
    /// Вызывается родителем после установки `frame` индикатора.
    /// - Parameters:
    ///   - lineLeft: отступ линии от левого края индикатора (= ширина кружка)
    ///   - lineWidth: ширина линии
    func layoutIndicator(lineLeft: CGFloat, lineWidth: CGFloat) {
        let diameter = indicatorConfig.circleRadius * 2
        circleView.frame = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        lineView.frame = CGRect(
            x: lineLeft,
            y: indicatorConfig.circleRadius - indicatorConfig.lineHeight / 2,
            width: lineWidth,
            height: indicatorConfig.lineHeight
        )
    }
}
