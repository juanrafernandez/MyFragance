import SwiftUI
import Kingfisher

// Vista genérica para generar la imagen de compartir
struct GenericPerfumeShareView: View {
    // Datos que recibe
    let title: String // Título personalizable
    let items: [ShareablePerfumeItem] // Usa el nuevo struct
    let selectedFilters: [String: [String]]
    let ratingRange: ClosedRange<Double>? // Rating personal (opcional)
    let perfumePopularityRange: ClosedRange<Double>
    let searchText: String

    // Rangos por defecto para comparación
    private let defaultRatingRange: ClosedRange<Double> = 0...10
    private let defaultPerfumePopularityRange: ClosedRange<Double> = 0...10

    // ViewModels necesarios
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    // Subtítulo (lógica similar, adaptada para ratingRange opcional)
    private var subtitleText: String? {
        var descriptions: [String] = []
        if !searchText.isEmpty { descriptions.append("Buscando \"\(searchText)\"") }
        if let genders = selectedFilters["Género"], !genders.isEmpty {
            let genderNames = genders.compactMap { Gender(rawValue: $0)?.displayName ?? $0 }
            descriptions.append("Género: \(genderNames.joined(separator: "/"))")
        }
        if let familiesKeys = selectedFilters["Familia Olfativa"], !familiesKeys.isEmpty {
             let familyNames = familiesKeys.compactMap { key in familyViewModel.familias.first { $0.key == key }?.name ?? key }
            descriptions.append("Familia(s): \(familyNames.joined(separator: "/"))")
        }
        if let seasons = selectedFilters["Temporada Recomendada"], !seasons.isEmpty {
            let seasonNames = seasons.compactMap { Season(rawValue: $0)?.displayName ?? $0 }
            descriptions.append("Temporada: \(seasonNames.joined(separator: "/"))")
        }
        // Mostrar rating personal solo si se pasó y es diferente al default
        if let personalRating = ratingRange, personalRating != defaultRatingRange {
            descriptions.append("Rating: \(Int(personalRating.lowerBound))-\(Int(personalRating.upperBound))")
        }
        if perfumePopularityRange != defaultPerfumePopularityRange {
            descriptions.append("Popularidad: \(Int(perfumePopularityRange.lowerBound))-\(Int(perfumePopularityRange.upperBound))")
        }
        // ... otros filtros ...

        return descriptions.isEmpty ? nil : descriptions.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Usa el título pasado como parámetro
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .padding(.bottom, 4)

            if let subtitle = subtitleText {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.bottom, 8)
            }

            // Itera sobre los ShareablePerfumeItem
            ForEach(items) { item in
                HStack(spacing: 12) {
                    // ✅ Fix: Use flatMap to safely create URL only if imageURL is valid
                    // Imagen (igual)
                    KFImage(item.perfume.imageURL.flatMap { URL(string: $0) })
                         .placeholder {
                             Image(systemName: "photo").resizable().scaledToFit()
                                 .frame(width: 50, height: 50).foregroundColor(.gray)
                                 .background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
                         }
                         .resizable().aspectRatio(contentMode: .fill)
                         .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 10)).clipped()

                    // Info del perfume (igual)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.perfume.name)
                            .font(.system(size: 16, weight: .semibold)).lineLimit(1)
                        Text(brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand)
                            .font(.system(size: 14)).foregroundColor(.secondary).lineLimit(1)

                        // Muestra el rating si existe, usando el tipo para el icono/color
                        if let ratingValue = item.displayRating {
                            HStack(spacing: 3) {
                                // Icono y color basados en ratingType
                                Image(systemName: item.ratingType == .personal ? "heart.fill" : "star.fill")
                                    .foregroundColor(item.ratingType == .personal ? .red : .yellow) // Ajusta color de estrella si prefieres
                                    .font(.caption)

                                Text("\(ratingValue, specifier: "%.1f")\(item.ratingType == .personal ? " / 10" : "")") // Añade "/ 10" solo para personal
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(item.ratingType == .personal ? .red : .gray) // Ajusta color de texto de estrella
                            }
                            .padding(.top, 1)
                        }
                    }
                    Spacer()
                }
                 if item.id != items.last?.id {
                     Divider().padding(.leading, 72)
                 }
            }

            Spacer()

            Text("Compartido desde [Nombre de tu App]") // ¡¡REEMPLAZA!!
                .font(.caption2).foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center).padding(.top, 10)
        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
    }
}
