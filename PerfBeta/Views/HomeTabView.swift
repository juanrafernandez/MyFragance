import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var familiaManager: FamiliaOlfativaManager
    @EnvironmentObject var profileManager: OlfactiveProfileManager
    let allPerfumes: [Perfume] = PerfumeManager().getAllPerfumes() // Usa una lista predeterminada

    @State private var selectedPerfume: Perfume? // Perfume seleccionado para detalle
    @State private var relatedPerfumes: [Perfume] = [] // Perfumes relacionados al seleccionado

    init() {
        // Cambia el color de los indicadores
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.3))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Saludo fijo
                GreetingSection(userName: "Juan")
                    .padding([.top, .horizontal], 16)
                    .background(Color("fondoClaro"))

                // Contenido desplazable
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Recomendaciones
                        RecommendationsCarousel(profiles: profileManager.profiles, onPerfumeTap: { perfume, selectedProfile in
                            selectedPerfume = perfume
                            relatedPerfumes = selectedProfile.perfumes
                        })

                        // Perfecto para esta temporada
                        SeasonalSection(allPerfumes: allPerfumes, onPerfumeTap: { perfume in
                            selectedPerfume = perfume
                            relatedPerfumes = allPerfumes // Puedes ajustar según la lógica
                        })

                        // ¿Sabías que...?
                        DidYouKnowSection()
                    }
                    .padding(.top, 16)
                    .background(Color("fondoClaro"))
                }
            }
            .background(Color("fondoClaro"))
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(perfume: perfume, relatedPerfumes: relatedPerfumes)
            }
        }
    }
}

// Sección de Saludo
struct GreetingSection: View {
    let userName: String

    var body: some View {
        let greetingMessage = getGreetingMessage(for: userName)
        Text(greetingMessage)
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(Color("textoPrincipal"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func getGreetingMessage(for name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 12 {
            return "Buenos días, \(name). ¿Qué fragancia buscas hoy?"
        } else if hour >= 12 && hour < 18 {
            return "Buenas tardes, \(name). ¿Buscas algo fresco para la tarde?"
        } else {
            return "Buenas noches, \(name). ¿Buscas nueva fragancia?"
        }
    }
}

// Tarjeta del Carrusel de Recomendaciones
struct RecommendationsCarousel: View {
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
                    RecommendationsCard(profile: profile, height: cardHeight, onPerfumeTap: { perfume in
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
struct RecommendationsCard: View {
    let profile: OlfactiveProfile
    let height: CGFloat
    let onPerfumeTap: (Perfume) -> Void

    var body: some View {
        ZStack {
            // Fondo degradado desde la mitad hacia la derecha
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: profile.familia.color)]),
                startPoint: .center,
                endPoint: .trailing
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            HStack(spacing: 20) {
                if let firstPerfume = profile.perfumes.first {
                    Button(action: {
                        onPerfumeTap(firstPerfume)
                    }) {
                        Image(firstPerfume.imagenURL)
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
                    Text(profile.perfumes.first?.nombre ?? "Desconocido")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    // Marca del perfume
                    Text(profile.perfumes.first?.marca ?? "Desconocido")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    // Lista de notas
                    ForEach(0..<5, id: \.self) { index in
                        if let note = profile.perfumes.first?.notasPrincipales[safe: index] {
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

// Sección de Perfecto para esta temporada
struct SeasonalSection: View {
    let allPerfumes: [Perfume]
    let onPerfumeTap: (Perfume) -> Void
    @EnvironmentObject var familiaManager: FamiliaOlfativaManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Perfecto para esta temporada")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal)

            let currentSeason = determineCurrentSeason()
            let matchingFamilies = familiaManager.familias.filter { $0.estacionRecomendada.contains(currentSeason) }
            let matchingPerfumes = allPerfumes.filter { perfume in
                matchingFamilies.contains(where: { $0.id == perfume.familia })
            }

            if matchingPerfumes.isEmpty {
                Text("No hay perfumes disponibles para esta temporada.")
                    .font(.subheadline)
                    .foregroundColor(Color("textoSecundario"))
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(matchingPerfumes, id: \.id) { perfume in
                            TrendingCard(perfume: perfume) {
                                onPerfumeTap(perfume)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func determineCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return "Primavera"
        case 6...8:
            return "Verano"
        case 9...11:
            return "Otoño"
        default:
            return "Invierno"
        }
    }
}

// Tarjeta de Perfume
struct TrendingCard: View {
    let perfume: Perfume
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(perfume.imagenURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 120)
                    .cornerRadius(8)

                Text(perfume.nombre)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("textoPrincipal"))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                Text(perfume.familia.capitalized)
                    .font(.system(size: 10))
                    .foregroundColor(Color("textoSecundario"))
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Sección ¿Sabías que...?
struct DidYouKnowSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Sabías que…?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal)

            Text("La vainilla es uno de los ingredientes más caros del mundo.")
                .font(.system(size: 14))
                .foregroundColor(Color("textoSecundario"))
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("grisSuave"))
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}
