import SwiftUI

class GradientBackgroundView: UIView {

    private var gradientLayer: CAGradientLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGradientLayer()
    }

    private func setupGradientLayer() {
        gradientLayer = CAGradientLayer()
        guard let gradientLayer = gradientLayer else { return } // Exit if layer couldn't be created
        gradientLayer.frame = bounds

        // Degradado agrupado en el primer tercio y degradado a blanco suave para el resto
        gradientLayer.colors = [UIColor.white.cgColor] // Default is now white
        gradientLayer.locations = [0.0, 0.2, 0.3, 0.4] // These locations are now irrelevant for initial white color
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        layer.addSublayer(gradientLayer)
    }

    func setGradientColors(colors: [UIColor]) {
        gradientLayer?.colors = colors.map { $0.cgColor }
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        // Update the gradient layer's frame whenever the view's bounds change
        gradientLayer?.frame = bounds
    }
}

// MARK: - GradientView (UIViewRepresentable) (sin cambios)
struct GradientView: UIViewRepresentable {
    var gradientColors: [Color]

    func makeUIView(context: Context) -> GradientBackgroundView {
        let gradientView = GradientBackgroundView()
        // Convert SwiftUI Colors to CGColors for GradientBackgroundView
        gradientView.setGradientColors(colors: gradientColors.map { UIColor($0) })
        return gradientView
    }

    func updateUIView(_ uiView: GradientBackgroundView, context: Context) {
        // Update gradient colors if they change
        uiView.setGradientColors(colors: gradientColors.map { UIColor($0) })
    }
}
