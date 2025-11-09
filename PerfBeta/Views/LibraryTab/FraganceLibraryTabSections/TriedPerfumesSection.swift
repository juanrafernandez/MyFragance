import SwiftUI
import Kingfisher

struct TriedPerfumesSection: View {
    let title: String
    let triedPerfumes: [TriedPerfume] // ✅ No necesita Binding - solo lectura
    let maxDisplayCount: Int
    let addAction: () -> Void
    @ObservedObject var userViewModel: UserViewModel // Recibe UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !triedPerfumes.isEmpty {
                    // ✅ CRITICAL FIX: Lazy loading - la vista se crea SOLO al navegar
                    NavigationLink {
                        TriedPerfumesListView(
                            familyViewModel: familyViewModel
                        )
                    } label: {
                        Text("Ver más")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("textoPrincipal"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("champan").opacity(0.1))
                            )
                    }
                }
            }
            .padding(.bottom, 5)

            // ✅ SIMPLIFICADO: Usar solo isLoadingTriedPerfumes
            if userViewModel.isLoadingTriedPerfumes {
                LoadingView(message: "Cargando perfumes...", style: .inline)
                    .frame(height: 100)
            }
            else if triedPerfumes.isEmpty {
                EmptyStateView(
                    type: .noTriedPerfumes,
                    action: addAction,
                    compact: true
                )
                .frame(height: 150)
            } else {
                // --- Mostrar lista de perfumes ---
                VStack(alignment: .leading, spacing: 1) {
                    // ✅ CRITICAL FIX: Usar búsqueda O(1) en lugar de O(n)
                    ForEach(triedPerfumes.prefix(maxDisplayCount)) { record in
                        TriedPerfumeRowView(record: record)
                    }
                }
                // --- Botón "Añadir Perfume" (sin cambios) ---
                Button(action: addAction) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Añadir Perfume")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("champan"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 10)
            }
        }
        // Asegúrate de inyectar perfumeViewModel donde uses TriedPerfumesSection
        // .environmentObject(yourPerfumeViewModelInstance)
    }
}

// MARK: - TriedPerfumeRowView (SIMPLIFICADA - patrón WishlistRowView)
/// ✅ REFACTOR: Vista de fila usando índice de perfumeViewModel
struct TriedPerfumeRowView: View {
    let record: TriedPerfume
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var showingDetailView = false

    // ✅ Perfume lookup: por ID (datos nuevos) o por key (datos legacy)
    private var perfume: Perfume? {
        // Primero intentar por ID (datos nuevos)
        if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: record.perfumeId) {
            return perfume
        }

        // Fallback: buscar por key (datos legacy antes del fix)
        return perfumeViewModel.perfumes.first(where: { $0.key == record.perfumeId })
    }

    var body: some View {
        Button {
            if perfume != nil {
                showingDetailView = true
            }
        } label: {
            HStack(spacing: 15) {
                // ✅ Imagen del perfume
                if let perfume = perfume {
                    KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                        .placeholder {
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .cacheMemoryOnly(false)
                        .diskCacheExpiration(.never)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let perfume = perfume {
                        Text(perfume.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                            .lineLimit(2)

                        Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Mostrar Rating con icono de corazón
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 12))
                    Text(String(format: "%.1f", record.rating))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("textoSecundario"))
                }
            }
            .padding(.vertical, 8)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetailView) {
            if let perfume = perfume {
                PerfumeLibraryDetailView(
                    perfume: perfume,
                    triedPerfume: record
                )
            }
        }
    }
}
