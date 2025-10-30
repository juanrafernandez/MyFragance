import SwiftUI
import Kingfisher

struct PerfumeCardView: View {
    let perfume: Perfume
    let brandName: String
    let family: String
    let popularity: Double?
    let score: Double?
    let showPopularity: Bool
    
    init(perfume: Perfume, brandName: String, family: String, score: Double? = nil, showPopularity: Bool = true) {
        self.perfume = perfume
        self.brandName = brandName
        self.family = family
        self.popularity = score ?? perfume.popularity
        self.score = showPopularity ? nil : score
        self.showPopularity = showPopularity
    }
    
    init(perfume: Perfume, brandViewModel: BrandViewModel, score: Double? = nil, showPopularity: Bool = true) {
        self.perfume = perfume
        self.brandName = brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand
        self.family = perfume.family
        self.popularity = score ?? perfume.popularity
        self.score = showPopularity ? nil : score
        self.showPopularity = showPopularity
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Contenido principal más compacto
            VStack(alignment: .center, spacing: 6) {
                // ✅ Fix: Don't pass asset name as URL string - let URL(string:) return nil for invalid URLs
                KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(height: 95)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .cornerRadius(6)
                
                // Grupo de textos más compacto
                VStack(spacing: 2) { // Espaciado interno reducido
                    Text(brandName)
                        .font(.system(size: 11, weight: .semibold)) // Reducido de 12
                        .foregroundColor(Color("textoSecundario"))
                        .lineLimit(1)
                    
                    Text(perfume.name)
                        .font(.system(size: 13, weight: .bold)) // Reducido de 14
                        .foregroundColor(Color("textoPrincipal"))
                        .lineLimit(1)
                    
                    Text(family.capitalized)
                        .font(.system(size: 11)) // Reducido de 12
                        .foregroundColor(Color("textoSecundario"))
                        .lineLimit(1)
                }
            }
            .frame(width: 140)
            .padding(8) // Reducido de 10 a 8
            .background(Color.white)
            .cornerRadius(10) // Reducido de 12 a 10
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2) // Sombra más sutil
            
            // Badge de score o popularidad
            if let score = score, !showPopularity {
                // Mostrar score si está disponible
                HStack(spacing: 1) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.pink)
                    Text(String(format: "%.0f%%", score))
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(6)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)
                .offset(x: -4, y: 4)
            } else if showPopularity {
                // Mostrar popularidad si no hay score
                HStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", popularity ?? score ?? 0))
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(6)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)
                .offset(x: -4, y: 4)
            }
        }
        .frame(width: 140)
    }
}
