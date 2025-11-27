import SwiftUI
import Kingfisher

// MARK: - Item de Perfume para Lista Vertical (Diseño Editorial)
struct PerfumeListItemView: View {
    let perfume: Perfume
    let score: Double
    let onTap: () -> Void

    private var displayBrandName: String {
        perfume.brandName ?? perfume.brand.capitalized
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 16) {
                // Imagen pequeña del perfume
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)

                    if let imageUrl = perfume.imageURL, let url = URL(string: imageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColor.textSecondary.opacity(0.3))
                    }
                }

                // Información del perfume
                VStack(alignment: .leading, spacing: 4) {
                    // Nombre del perfume
                    Text(perfume.name)
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(1)

                    // Marca
                    Text(displayBrandName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Porcentaje de compatibilidad
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score))%")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(AppColor.textPrimary)

                    Text("match")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
