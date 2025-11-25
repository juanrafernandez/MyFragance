import SwiftUI

// MARK: - PerfumeCardRow (Sin cambios)
struct PerfumeCardRow: View {
    let perfume: Perfume
    @ObservedObject var brandViewModel: BrandViewModel
    
    var body: some View {
        HStack {
            Image(perfume.imageURL ?? "givenchy_gentleman_Intense")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(perfume.name)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)
                
                if let brand = brandViewModel.getBrand(byKey: perfume.brand) { // Obtener Brand con brandViewModel
                    Text(brand.name) // Mostrar el nombre de la marca
                        .font(.subheadline)
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Marca no encontrada") // Mensaje si la marca no se encuentra (opcional)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Image(systemName: "star.fill")
                    Text(String(format: "%.1f", perfume.popularity ?? 0.0))
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
