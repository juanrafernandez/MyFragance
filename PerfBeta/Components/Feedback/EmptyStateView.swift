import SwiftUI

/// Sistema unificado de Empty States para mostrar pantallas vacías con contexto y CTAs
/// Mejora crítica de UX identificada en UX_AUDIT_REPORT.md

// MARK: - Empty State Type
/// Tipos predefinidos de estados vacíos con mensajes user-friendly
enum EmptyStateType {
    case noPerfumesInLibrary      // Biblioteca vacía
    case noTriedPerfumes          // No perfumes probados
    case noWishlist               // Wishlist vacío
    case noRecommendations        // Sin recomendaciones
    case noSearchResults          // Búsqueda sin resultados
    case noProfilesCreated        // Sin perfiles olfativos
    case noFilterResults          // Filtros sin resultados
    case noResults(String)        // Genérico con mensaje custom

    // MARK: - Visual Properties

    /// Icono SF Symbol apropiado para cada tipo
    var icon: String {
        switch self {
        case .noPerfumesInLibrary:
            return "sparkles"
        case .noTriedPerfumes:
            return "nose"
        case .noWishlist:
            return "heart.slash"
        case .noRecommendations:
            return "star.slash"
        case .noSearchResults:
            return "magnifyingglass"
        case .noProfilesCreated:
            return "person.crop.circle.badge.questionmark"
        case .noFilterResults:
            return "line.3.horizontal.decrease.circle"
        case .noResults:
            return "tray"
        }
    }

    /// Color del icono (para dar personalidad visual)
    var iconColor: Color {
        switch self {
        case .noPerfumesInLibrary:
            return .purple
        case .noTriedPerfumes:
            return .blue
        case .noWishlist:
            return .pink
        case .noRecommendations:
            return .orange
        case .noSearchResults:
            return .gray
        case .noProfilesCreated:
            return .indigo
        case .noFilterResults:
            return .teal
        case .noResults:
            return .secondary
        }
    }

    /// Título claro y descriptivo
    var title: String {
        switch self {
        case .noPerfumesInLibrary:
            return "Tu Biblioteca Está Vacía"
        case .noTriedPerfumes:
            return "Aún No Has Probado Perfumes"
        case .noWishlist:
            return "Tu Lista de Deseos Está Vacía"
        case .noRecommendations:
            return "Sin Recomendaciones"
        case .noSearchResults:
            return "No Encontramos Resultados"
        case .noProfilesCreated:
            return "No Tienes Perfiles Olfativos"
        case .noFilterResults:
            return "No Hay Resultados con Estos Filtros"
        case .noResults(let message):
            return message
        }
    }

    /// Mensaje explicativo y user-friendly
    var message: String {
        switch self {
        case .noPerfumesInLibrary:
            return "Comienza a explorar nuestra colección de fragancias y añade tus favoritos para verlos aquí."
        case .noTriedPerfumes:
            return "Registra los perfumes que has probado para llevar un seguimiento de tus experiencias olfativas."
        case .noWishlist:
            return "Explora perfumes y añade los que te gustaría probar a tu lista de deseos."
        case .noRecommendations:
            return "Completa tu perfil olfativo respondiendo el test para recibir recomendaciones personalizadas."
        case .noSearchResults:
            return "Intenta con otros términos de búsqueda o explora nuestra colección completa."
        case .noProfilesCreated:
            return "Crea tu perfil olfativo para obtener recomendaciones personalizadas basadas en tus preferencias."
        case .noFilterResults:
            return "Prueba ajustando los filtros para encontrar más perfumes que se adapten a tus gustos."
        case .noResults:
            return "No hay elementos para mostrar en este momento."
        }
    }

    /// Texto del botón CTA (nil si no aplica)
    var ctaTitle: String? {
        switch self {
        case .noPerfumesInLibrary:
            return "Explorar Perfumes"
        case .noTriedPerfumes:
            return "Añadir Perfume"
        case .noWishlist:
            return "Explorar Colección"
        case .noRecommendations:
            return "Hacer Test Olfativo"
        case .noSearchResults:
            return "Ver Todos los Perfumes"
        case .noProfilesCreated:
            return "Crear Mi Perfil"
        case .noFilterResults:
            return "Limpiar Filtros"
        case .noResults:
            return nil // Genérico sin CTA
        }
    }
}

// MARK: - Empty State View
/// Componente reutilizable para mostrar estados vacíos con contexto y guidance
struct EmptyStateView: View {
    // MARK: - Properties
    let type: EmptyStateType
    let action: (() -> Void)?
    let compact: Bool  // ✅ Modo compacto para listas

    // MARK: - Initializers
    init(type: EmptyStateType, action: (() -> Void)? = nil, compact: Bool = false) {
        self.type = type
        self.action = action
        self.compact = compact
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: compact ? 12 : 24) {
            if !compact {
                Spacer()
            }

            // Contenido textual
            VStack(spacing: compact ? 8 : 12) {
                Text(type.title)
                    .font(compact ? .headline : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(type.message)
                    .font(compact ? .caption : .body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, compact ? 16 : 32)

            // Botón CTA (solo si existe)
            if let ctaTitle = type.ctaTitle, let action = action {
                AppButton(
                    title: ctaTitle,
                    action: action,
                    style: .accent,
                    size: compact ? .medium : .large,
                    icon: "arrow.right",
                    iconPosition: .trailing
                )
                .frame(maxWidth: compact ? 200 : 280)
                .padding(.top, compact ? 4 : 8)
            }

            if !compact {
                Spacer()
            }
        }
        .padding(compact ? 16 : 0)
        .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity)
        // ✅ Sin background - deja pasar el degradado de la pantalla
    }
}

// MARK: - View Extension
extension View {
    /// Muestra EmptyStateView cuando una colección está vacía
    /// - Parameters:
    ///   - isEmpty: Binding que indica si está vacío
    ///   - emptyStateType: Tipo de estado vacío
    ///   - action: Acción del CTA
    func emptyState(
        _ isEmpty: Bool,
        type emptyStateType: EmptyStateType,
        action: (() -> Void)? = nil
    ) -> some View {
        ZStack {
            if isEmpty {
                EmptyStateView(type: emptyStateType, action: action)
                    .transition(.opacity)
            } else {
                self
            }
        }
    }
}

// MARK: - Previews
#Preview("Biblioteca Vacía") {
    EmptyStateView(
        type: .noPerfumesInLibrary,
        action: {
            #if DEBUG
            print("Explorar perfumes tapped")
            #endif
        }
    )
}

#Preview("Sin Perfumes Probados") {
    EmptyStateView(
        type: .noTriedPerfumes,
        action: {
            #if DEBUG
            print("Añadir primer perfume tapped")
            #endif
        }
    )
}

#Preview("Wishlist Vacía") {
    EmptyStateView(
        type: .noWishlist,
        action: {
            #if DEBUG
            print("Explorar colección tapped")
            #endif
        }
    )
}

#Preview("Sin Recomendaciones") {
    EmptyStateView(
        type: .noRecommendations,
        action: {
            #if DEBUG
            print("Hacer test olfativo tapped")
            #endif
        }
    )
}

#Preview("Sin Resultados de Búsqueda") {
    EmptyStateView(
        type: .noSearchResults,
        action: {
            #if DEBUG
            print("Ver todos los perfumes tapped")
            #endif
        }
    )
}

#Preview("Sin Perfiles Creados") {
    EmptyStateView(
        type: .noProfilesCreated,
        action: {
            #if DEBUG
            print("Crear perfil tapped")
            #endif
        }
    )
}

#Preview("Sin Resultados de Filtros") {
    EmptyStateView(
        type: .noFilterResults,
        action: {
            #if DEBUG
            print("Limpiar filtros tapped")
            #endif
        }
    )
}

#Preview("Estado Genérico Sin CTA") {
    EmptyStateView(
        type: .noResults("No Hay Datos Disponibles")
    )
}

#Preview("Comparación Multiple") {
    ScrollView {
        VStack(spacing: 40) {
            Group {
                EmptyStateView(type: .noPerfumesInLibrary, action: {})
                    .frame(height: 400)
                    .border(Color.gray.opacity(0.3))

                EmptyStateView(type: .noTriedPerfumes, action: {})
                    .frame(height: 400)
                    .border(Color.gray.opacity(0.3))

                EmptyStateView(type: .noWishlist, action: {})
                    .frame(height: 400)
                    .border(Color.gray.opacity(0.3))
            }
        }
        .padding()
    }
}

#Preview("Interactive Demo") {
    struct EmptyStateDemo: View {
        @State private var selectedType: EmptyStateType = .noPerfumesInLibrary

        let types: [(String, EmptyStateType)] = [
            ("Biblioteca", .noPerfumesInLibrary),
            ("Probados", .noTriedPerfumes),
            ("Wishlist", .noWishlist),
            ("Recomendaciones", .noRecommendations),
            ("Búsqueda", .noSearchResults),
            ("Perfiles", .noProfilesCreated),
            ("Filtros", .noFilterResults),
            ("Genérico", .noResults("Sin Datos"))
        ]

        var body: some View {
            VStack(spacing: 0) {
                // Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(types, id: \.0) { name, type in
                            Button(name) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedType = type
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                isSelected(type) ? Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                isSelected(type) ? .white : .primary
                            )
                            .cornerRadius(20)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))

                // Empty State Display
                EmptyStateView(
                    type: selectedType,
                    action: {
                        #if DEBUG
                        print("Action for: \(selectedType.title)")
                        #endif
                    }
                )
                .id(selectedType.title) // Force refresh animation
            }
        }

        func isSelected(_ type: EmptyStateType) -> Bool {
            type.title == selectedType.title
        }
    }

    return EmptyStateDemo()
}
