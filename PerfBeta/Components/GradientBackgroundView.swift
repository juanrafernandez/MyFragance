import SwiftUI
import UIKit

// MARK: - GradientBackgroundView Modificada
class GradientBackgroundView: UIView {

    private var gradientLayer: CAGradientLayer?

    // Múltiplo para la altura del gradiente (ajusta según necesites > 0.5)
    private let gradientHeightMultiplier: CGFloat = 0.65 // Ejemplo: 65% de la altura

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
        guard let gradientLayer = gradientLayer else { return }

        // Establecer frame inicial a los bounds (se ajustará en layoutSubviews)
        gradientLayer.frame = self.bounds

        // NO establecer colors ni locations aquí, se hará en setGradientColors
        // SÍ establecer puntos de dirección del gradiente
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0) // Arriba
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)   // Abajo

        // Insertar el layer al fondo
        layer.insertSublayer(gradientLayer, at: 0)
    }

    func setGradientColors(colors: [UIColor]) {
        gradientLayer?.colors = colors.map { $0.cgColor }

        // --- CAMBIO 2: Establecer locations DINÁMICAMENTE ---
        // Basado en el número de colores y el multiplicador de altura.
        // Para 4 colores y un multiplicador de 0.65, distribuimos los colores
        // dentro de ese 65% superior.
        if colors.count == 4 {
            // El último punto (donde el blanco es dominante) coincide con el multiplicador
            gradientLayer?.locations = [
                0.0,                                  // Inicio del primer color
                NSNumber(value: gradientHeightMultiplier * 0.33), // Punto aprox. 1/3 dentro del área del gradiente
                NSNumber(value: gradientHeightMultiplier * 0.66), // Punto aprox. 2/3 dentro del área del gradiente
                NSNumber(value: gradientHeightMultiplier)         // Fin del área de color, inicio del blanco total
            ]
            // Ejemplo con 0.65: [0.0, 0.2145, 0.429, 0.65]
        } else if colors.count == 2 {
            gradientLayer?.locations = [0.0, NSNumber(value: gradientHeightMultiplier)] // Ejemplo: [0.0, 0.65]
        }
         else {
            // Fallback para otros números de colores (distribución lineal simple)
            gradientLayer?.locations = nil
        }
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        // --- CAMBIO 1: Usar el multiplicador definido ---
        // Calcular la altura del gradiente como una fracción de la altura total de la vista
        let gradientHeight: CGFloat = bounds.height * gradientHeightMultiplier
        gradientLayer?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: gradientHeight)
    }
}

// MARK: - GradientView (UIViewRepresentable) - SIN CAMBIOS
struct GradientView: UIViewRepresentable {
    var preset: GradientPreset

    func makeUIView(context: Context) -> GradientBackgroundView {
        let gradientView = GradientBackgroundView()
        // Llama a setGradientColors, que ahora también configura las locations
        gradientView.setGradientColors(colors: preset.colors.map { UIColor($0) })
        return gradientView
    }

    func updateUIView(_ uiView: GradientBackgroundView, context: Context) {
        // Actualiza los colores y locations si el preset cambia
        uiView.setGradientColors(colors: preset.colors.map { UIColor($0) })
    }
}

struct GradientLinearView: View {
    let preset: GradientPreset // Usaba el AppStorage

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: preset.colors), // preset.colors debía estar definido
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
