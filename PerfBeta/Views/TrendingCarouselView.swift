import SwiftUI

struct TrendingCarouselView: View {
    let perfumes = PerfumeManager().getAllPerfumes() // Lista de perfumes
    @State private var currentIndex = 0

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tendencias del Momento")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.leading, 16)

            // Carrusel
            TabView(selection: $currentIndex) {
                ForEach(perfumes, id: \.id) { perfume in
                    ZStack {
                        // Fondo gradiente
                        LinearGradient(
                            gradient: Gradient(colors: [Color("champan"), Color("grisClaro")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 16)

//                        VStack(spacing: 8) {
//                            // Imagen del perfume
//                            Image(perfume.id ?? "placeholder")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(height: 120)
//
//                            // Nombre del perfume
//                            Text(perfume.nombre)
//                                .font(.system(size: 18, weight: .medium))
//                                .foregroundColor(Color("textoPrincipal"))
//
//                            // Descripción breve
//                            Text(perfume.familia.capitalized)
//                                .font(.system(size: 14))
//                                .foregroundColor(Color("textoSecundario"))
//                        }
//                        .padding()
                    }
                    .frame(height: 220)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))

            // Indicadores de Paginación
            HStack {
                ForEach(perfumes.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color("champan") : Color("grisClaro"))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
    }
}
