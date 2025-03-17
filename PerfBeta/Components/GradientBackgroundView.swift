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
        let gradientHeight: CGFloat = 250 // Ajusta según necesites
        gradientLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: gradientHeight)
        
        gradientLayer.colors = [
            UIColor(red: 251/255, green: 237/255, blue: 213/255, alpha: 1).cgColor, // Color crema claro
            UIColor.white.cgColor // Blanco
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        layer.addSublayer(gradientLayer)
    }

    func setGradientColors(colors: [UIColor]) {
        gradientLayer?.colors = colors.map { $0.cgColor }
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        let gradientHeight: CGFloat = bounds.height * 0.35 // Ajusta la altura proporcionalmente
        gradientLayer?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: gradientHeight)
    }
}

// MARK: - GradientView (UIViewRepresentable)
struct GradientView: UIViewRepresentable {
    var preset: GradientPreset // Ahora preset YA NO ES opcional, y usa el enum movido

    func makeUIView(context: Context) -> GradientBackgroundView {
        let gradientView = GradientBackgroundView()
        // Usa SIEMPRE los colores del preset
        gradientView.setGradientColors(colors: preset.colors.map { UIColor($0) })
        return gradientView
    }

    func updateUIView(_ uiView: GradientBackgroundView, context: Context) {
        // Actualiza los colores si el preset cambia
        uiView.setGradientColors(colors: preset.colors.map { UIColor($0) })
    }
}
