import SwiftUI
import Kingfisher

struct GenericPerfumeRowView: View {
    let data: PerfumeRowDisplayData

    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var perfumeName: String?
    @State private var brandName: String?
    @State private var isLoading = false

    var body: some View {
        Button(action: data.onTapAction) {
            HStack(spacing: 15) {
                KFImage(URL(string: data.imageURL ?? ""))
                    .placeholder {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    if let name = perfumeName {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(2)
                    } else if isLoading {
                        Text("Cargando nombre...")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    } else {
                        Text(data.perfumeKey)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }

                    if let brand = brandName {
                        Text(brand)
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.textSecondary)
                            .lineLimit(1)
                    } else if isLoading {
                        Text("Cargando marca...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text(data.brandKey)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // --- Rating Display (Personal o General) ---
                if let pRating = data.personalRating {
                    // Muestra Rating Personal al final
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill") // Icono Corazón
                            .foregroundColor(.red)       // Color Rojo
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", pRating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColor.textPrimary) // O .red si prefieres
                    }
                } else if let gRating = data.generalRating {
                     // Muestra Rating General si no hay personal
                     HStack(spacing: 3) {
                         Image(systemName: "star.fill") // Icono Estrella
                             .foregroundColor(.yellow)   // Color Amarillo
                             .font(.system(size: 12))
                         Text(String(format: "%.1f", gRating))
                             .font(.system(size: 12, weight: .medium))
                             .foregroundColor(AppColor.textPrimary) // O .gray
                     }
                }
                // Si no hay ni personal ni general, no se muestra nada aquí.
            }
            .padding(.vertical, 10)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
        .task {
            if perfumeName == nil { perfumeName = data.initialPerfumeName }
            if brandName == nil { brandName = data.initialBrandName }

            if perfumeName == nil || brandName == nil {
                await loadMissingData()
            }
        }
        .onChange(of: data.initialPerfumeName) {
            perfumeName = data.initialPerfumeName
        }
        .onChange(of: data.initialBrandName) {
            brandName = data.initialBrandName
        }
    }

    private func loadMissingData() async {
        guard !isLoading else { return }
        isLoading = true

        if perfumeName == nil {
            do {
                if let fetchedPerfume = try await perfumeViewModel.getPerfume(byKey: data.perfumeKey) {
                    perfumeName = fetchedPerfume.name
                } else {
                    perfumeName = data.perfumeKey
                }
            } catch {
                #if DEBUG
                print("Error loading perfume \(data.perfumeKey): \(error)")
                #endif
                perfumeName = data.perfumeKey
            }
        }

        if brandName == nil {
            if let fetchedBrand = brandViewModel.getBrand(byKey: data.brandKey) {
                 brandName = fetchedBrand.name
            } else {
                #if DEBUG
                print("Marca \(data.brandKey) no encontrada en BrandViewModel (posiblemente no cargada aún)")
                #endif
                brandName = data.brandKey
            }
        }

        isLoading = false
    }
}

struct PerfumeRowDisplayData: Identifiable {
    let id: String // Necesario para ForEach. Puede ser perfumeKey o recordId.
    let perfumeKey: String
    let brandKey: String
    let imageURL: String?
    let initialPerfumeName: String? // Nombre ya conocido (si viene de TriedPerfumeDisplayItem)
    let initialBrandName: String?   // Nombre ya conocido (si se resolvió antes)

    // Datos opcionales específicos
    let personalRating: Double? // Para TriedPerfumes
    let generalRating: Double?  // Para Wishlist (¿o popularidad?)

    // Acción a ejecutar al pulsar
    let onTapAction: () -> Void
}
