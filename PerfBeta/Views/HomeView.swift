import SwiftUI

struct HomeView: View {
    init() {
        // Cambia el color de los indicadores
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal")) // Color del indicador activo
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.3)) // Color de los indicadores inactivos
    }

    let recommendationsProfiles = mockProfiles // Perfiles simulados
    let seasonalPerfumes = MockPerfumes.perfumes.filter {
        $0.familia == "verdes" || $0.familia == "citricos" || $0.familia == "amaderados"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Saludo dinámico
                GreetingSection(userName: "Lisa")

                // Recomendaciones
                RecommendationsCarousel(profiles: recommendationsProfiles)

                // Perfecto para esta temporada
                SeasonalSection(perfumes: seasonalPerfumes)

                // ¿Sabías que...?
                DidYouKnowSection()
            }
            .padding(.top)
            .background(Color("fondoClaro"))
        }
    }
}


// Tarjeta del Carrusel de Recomendaciones
struct RecommendationsCarousel: View {
    let profiles: [OlfactiveProfile]
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
                    RecommendationsCard(profile: profile, height: cardHeight)
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

    var body: some View {
        ZStack {
            // Fondo degradado desde la mitad hacia la derecha
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: profileGradientColor(for: profile))]),
                startPoint: .center,
                endPoint: .trailing
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            HStack {
                // Imagen del perfume
                Image(profile.perfumes.first?.image_name ?? "placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: height - 40) // Ajusta la imagen a la altura
                    .cornerRadius(8)

                Spacer()

                // Información del perfume
                VStack(alignment: .leading, spacing: 8) {
                    // Título del perfume
                    Text(profile.perfumes.first?.nombre ?? "Desconocido")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    // Lista de notas
                    ForEach(0..<5, id: \.self) { index in
                        if let note = profile.perfumes.first?.notas[safe: index] {
                            Text(note)
                                .font(.system(size: index == 0 ? 16 : 14, weight: index == 0 ? .bold : .regular))
                                .foregroundColor(index == 0 ? Color("textoPrincipal") : Color("textoSecundario"))
                        }
                    }
                }
                .padding(.trailing, 60)
            }
            .padding(.horizontal)
        }
        .frame(width: UIScreen.main.bounds.width * 0.95, height: height) // Ajusta el ancho y la altura
    }

    func profileGradientColor(for profile: OlfactiveProfile) -> String {
        switch profile.name.lowercased() {
        case "cítrico":
            return "#FFD6A5"
        case "floral":
            return "#FFD1DC"
        case "amaderado":
            return "#B2A596"
        case "oriental":
            return "#F8BBD0"
        case "acuático":
            return "#AEE7FF"
        case "verdes":
            return "#B8F3C3"
        default:
            return "#F0F0F0" // Color neutro por defecto
        }
    }
}



// Extensión para evitar índices fuera de rango
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Sección de Perfecto para esta temporada
struct SeasonalSection: View {
    let perfumes: [Perfume]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Perfecto para esta temporada")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(perfumes, id: \.id) { perfume in
                        TrendingCard(perfume: perfume)
                    }
                }
                .padding(.horizontal)
            }
        }
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

// Tarjeta de Perfume
struct TrendingCard: View {
    let perfume: Perfume

    var body: some View {
        VStack(spacing: 6) {
            Image(perfume.image_name)
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
}

// Sección de Saludo
struct GreetingSection: View {
    let userName: String

    var body: some View {
        let greetingMessage = getGreetingMessage(for: userName)
        Text(greetingMessage)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(Color("textoPrincipal"))
            .padding(.horizontal)
    }

    func getGreetingMessage(for name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 12 {
            return "Buenos días, \(name). ¿Qué fragancia buscas hoy?"
        } else if hour >= 12 && hour < 18 {
            return "Buenas tardes, \(name). ¿Buscas algo fresco para la tarde?"
        } else {
            return "Buenas noches, \(name). ¿Algo especial para esta noche?"
        }
    }
}
