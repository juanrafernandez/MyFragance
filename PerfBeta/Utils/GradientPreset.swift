import SwiftUI
import UIKit

// MARK: - Gradient Presets (DEFINICIÓN DEL ENUM - AHORA EN GradientStyles.swift)
enum GradientPreset: String, CaseIterable, Identifiable, Codable, Hashable {
    case champan = "Champán"
    case lila = "Lila"
    case verde = "Verde"

    var id: Self { self }

    var colors: [Color] {
        switch self {
        case .champan:
            return [
                Color("champanOscuro").opacity(0.5),
                Color("champan").opacity(0.5),
                Color("champanClaro").opacity(0.5),
                .white
            ]
        case .lila:
            return [
                Color(red: 0.8, green: 0.6, blue: 0.8).opacity(0.5), // Lila oscuro
                Color(red: 0.85, green: 0.7, blue: 0.85).opacity(0.5), // Lila medio
                Color(red: 0.9, green: 0.8, blue: 0.9).opacity(0.5), // Lila claro
                .white
            ]
        case .verde:
            return [
                Color(red: 0.6, green: 0.8, blue: 0.6).opacity(0.5), // Verde oscuro
                Color(red: 0.7, green: 0.85, blue: 0.7).opacity(0.5), // Verde medio
                Color(red: 0.8, green: 0.9, blue: 0.8).opacity(0.5), // Verde claro
                .white
            ]
        }
    }
}
