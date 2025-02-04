import SwiftUI

// Sección de Perfecto para esta temporada
struct HomeSeasonalSectionView: View {
    let allPerfumes: [Perfume]
    let onPerfumeTap: (Perfume) -> Void
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Perfecto para esta temporada")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal)

            let currentSeason = determineCurrentSeason()
            let matchingFamilies = familiaOlfativaViewModel.familias.filter { $0.recommendedSeason.contains(currentSeason) }
            let matchingPerfumes = allPerfumes.filter { perfume in
                matchingFamilies.contains(where: { $0.id == perfume.family })
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
                
                Image(perfume.imageURL ?? "placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 120)
                    .cornerRadius(8)
                
                Text(perfume.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("textoPrincipal"))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(perfume.family.capitalized)
                    .font(.system(size: 10))
                    .foregroundColor(Color("textoSecundario"))
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

