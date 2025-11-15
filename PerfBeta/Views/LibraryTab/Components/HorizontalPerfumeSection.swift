import SwiftUI

/// ⚠️ NOTA: Este archivo existe para referencia pero actualmente NO se usa
/// La implementación actual está inline en FragranceLibraryTabView como HorizontalPerfumeSectionView
/// Mantener este archivo actualizado por si se necesita extraer en el futuro

/// Sección genérica con scroll horizontal de perfumes (máximo 5)
/// Usado en FragranceLibraryTabView para "Probados" y "Deseados"
struct HorizontalPerfumeSection: View {
    // MARK: - Nested Types
    struct PerfumeWithRating: Identifiable {
        let id: String
        let perfume: Perfume
        let rating: Double?

        init(perfume: Perfume, rating: Double? = nil) {
            self.id = perfume.id
            self.perfume = perfume
            self.rating = rating
        }
    }

    // MARK: - Properties
    let title: String
    let perfumesWithRatings: [PerfumeWithRating]
    let maxDisplay: Int = 5
    let emptyMessage: String
    let showPersonalRatings: Bool  // ✅ NEW: Control para mostrar ratings personales
    let onViewAll: () -> Void
    let onPerfumeSelect: (Perfume) -> Void

    @EnvironmentObject var brandViewModel: BrandViewModel

    // MARK: - Computed Properties
    private var displayPerfumes: [PerfumeWithRating] {
        Array(perfumesWithRatings.prefix(maxDisplay))
    }

    private var hasMore: Bool {
        perfumesWithRatings.count > maxDisplay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con título y botón "Ver todos"
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("textoPrincipal"))

                Spacer()

                if !perfumesWithRatings.isEmpty {
                    Button(action: onViewAll) {
                        HStack(spacing: 4) {
                            Text("Ver todos")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color("champan"))
                    }
                }
            }

            // Contenido: Scroll horizontal o empty state
            if perfumesWithRatings.isEmpty {
                emptyStateView
            } else {
                scrollContent
            }
        }
    }

    // MARK: - Scroll Content
    private var scrollContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(displayPerfumes) { item in
                        PerfumeCard(
                            perfume: item.perfume,
                            brandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand,
                            style: .compact,
                            size: .small,
                            showsFamily: true,
                            showsRating: showPersonalRatings,  // ✅ Solo mostrar rating en probados
                            personalRating: showPersonalRatings ? item.rating : nil
                        ) {
                            onPerfumeSelect(item.perfume)
                        }
                        .frame(width: 120)
                    }
                }
                .padding(.vertical, 4)
            }

            // Botón "Ver más" si hay más de 5 perfumes
            if hasMore {
                viewMoreButton
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text(emptyMessage)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Ver Más Button
    private var viewMoreButton: some View {
        Button(action: onViewAll) {
            HStack {
                Spacer()
                Text("Ver más")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("champan").opacity(0.1))
            )
            .foregroundColor(Color("champan"))
        }
    }
}

// MARK: - Preview
#Preview {
    let mockPerfumes = [
        Perfume(
            id: "1",
            name: "Sauvage Elixir",
            brand: "dior",
            key: "sauvage_elixir",
            family: "woody",
            subfamilies: ["spicy"],
            topNotes: [],
            heartNotes: [],
            baseNotes: [],
            projection: "strong",
            intensity: "strong",
            duration: "long",
            recommendedSeason: ["spring"],
            associatedPersonalities: [],
            occasion: [],
            popularity: 9.5,
            year: 2021,
            perfumist: nil,
            imageURL: "",
            description: "Intensa y magnética",
            gender: "masculine",
            price: "premium",
            createdAt: nil,
            updatedAt: nil
        ),
        Perfume(
            id: "2",
            name: "Aventus",
            brand: "creed",
            key: "aventus",
            family: "fruity",
            subfamilies: ["woody"],
            topNotes: [],
            heartNotes: [],
            baseNotes: [],
            projection: "strong",
            intensity: "strong",
            duration: "long",
            recommendedSeason: ["summer"],
            associatedPersonalities: [],
            occasion: [],
            popularity: 9.8,
            year: 2010,
            perfumist: nil,
            imageURL: "",
            description: "Icónico y poderoso",
            gender: "masculine",
            price: "luxury",
            createdAt: nil,
            updatedAt: nil
        )
    ]

    let mockPerfumesWithRatings = mockPerfumes.map {
        HorizontalPerfumeSection.PerfumeWithRating(perfume: $0, rating: 4.5)
    }

    return ZStack {
        GradientView(preset: .champan)
            .edgesIgnoringSafeArea(.all)

        VStack(spacing: 30) {
            // Con perfumes y ratings
            HorizontalPerfumeSection(
                title: "Tus Perfumes Probados",
                perfumesWithRatings: mockPerfumesWithRatings,
                emptyMessage: "Aún no has probado ningún perfume",
                showPersonalRatings: true,  // ✅ Mostrar ratings personales
                onViewAll: {},
                onPerfumeSelect: { _ in }
            )
            .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))

            Divider()

            // Empty state (wishlist no tiene ratings personales)
            HorizontalPerfumeSection(
                title: "Tu Lista de Deseos",
                perfumesWithRatings: [],
                emptyMessage: "Tu lista de deseos está vacía",
                showPersonalRatings: false,  // ✅ NO mostrar ratings personales
                onViewAll: {},
                onPerfumeSelect: { _ in }
            )
            .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
        }
        .padding()
    }
}
