import SwiftUI
import Kingfisher

struct PerfumeCarouselItem: View {
    let perfume: Perfume
    let score: Double
    @EnvironmentObject var brandViewModel: BrandViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .topTrailing) {
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
                    .frame(width: 90, height: 100)
                    .cornerRadius(12)
                
                Text("\(Int(score))%") // Mostrar el score como porcentaje
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.green)
                    .cornerRadius(6)
            }
            .aspectRatio(1, contentMode: .fit)

            Text(perfume.name)
                .font(.system(size: 12, weight: .thin))
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 6)

            let brandKey = perfume.brand
            if let brand = brandViewModel.getBrand(byKey: brandKey) {
                Text(brand.name.capitalized)
                    .font(.system(size: 10, weight: .thin))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 3)
            } else {
                Text("Brand N/A")
                    .font(.system(size: 9, weight: .thin))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 3)
            }
        }
    }
}
