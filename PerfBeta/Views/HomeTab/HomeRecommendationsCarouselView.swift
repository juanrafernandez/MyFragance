import SwiftUI

// Tarjeta del Carrusel de Recomendaciones
struct HomeRecommendationsCarouselView: View {
    let profiles: [OlfactiveProfile]
    let onPerfumeTap: (Perfume, OlfactiveProfile) -> Void
    @State private var currentPage: Int = 0

    private let cardHeight: CGFloat = 220 // Altura de la tarjeta

    var body: some View {
        VStack(alignment: .leading) {
            // Título de la sección
            Text("Recomendaciones")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))

            // Carrusel de fichas
            TabView(selection: $currentPage) {
                ForEach(Array(profiles.enumerated()), id: \.offset) { index, profile in
                    HomeRecommendationsCardView(profile: profile, height: cardHeight, onPerfumeTap: { perfume in
                        onPerfumeTap(perfume, profile)
                    })
                        .frame(width: UIScreen.main.bounds.width * 0.9, height: cardHeight)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: cardHeight + 30)
        }
        .padding(.horizontal) // Asegura un espaciado uniforme
    }
}

// Tarjeta del Carrusel de Recomendaciones
struct HomeRecommendationsCardView: View {
    let profile: OlfactiveProfile
    let height: CGFloat
    let onPerfumeTap: (Perfume) -> Void
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        ZStack {
            // Fondo degradado desde la mitad hacia la derecha
            let familyColor = familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyColor ?? "#FFFFFF"

            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: familyColor)]),
                startPoint: .center,
                endPoint: .trailing
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            HStack(spacing: 20) {
                if let firstPerfume = perfumeViewModel.perfumes.first {
                    Button(action: {
                        onPerfumeTap(firstPerfume)
                    }) {
                        Image(firstPerfume.imageURL ?? "placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: height - 40)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Información del perfume
                VStack(alignment: .leading, spacing: 8) {
                    // Nombre del perfil
                    Text(profile.name)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color("textoPrincipal"))

                    // Título del perfume
                    Text(perfumeViewModel.perfumes.first?.name ?? "Desconocido")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    // Marca del perfume
                    Text(perfumeViewModel.perfumes.first?.brand ?? "Desconocido")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    // Lista de notas
                    ForEach(0..<5, id: \.self) { index in
                        if let note = perfumeViewModel.perfumes.first?.baseNotes?[safe: index] {
                            Text(note)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color("textoSecundario"))
                        }
                    }
                }
                .padding(.top, -10)
                .padding(.trailing, 20)
            }
            .padding(.horizontal)
        }
        .frame(width: UIScreen.main.bounds.width * 0.95, height: height)
    }
}
