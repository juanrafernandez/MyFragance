import SwiftUI
import Kingfisher

struct TriedPerfumesSection: View {
    let title: String
    let triedPerfumes: [TriedPerfume] // ✅ No necesita Binding - solo lectura
    let maxDisplayCount: Int
    let addAction: () -> Void
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(AppColor.textPrimary)
                    .onAppear {
                        #if DEBUG
                        print("📋 [TriedPerfumesSection] Showing \(triedPerfumes.count) tried perfumes")
                        print("   - Metadata index: \(perfumeViewModel.metadataIndex.count) perfumes")
                        print("   - First few IDs: \(triedPerfumes.prefix(3).compactMap { $0.perfumeId })")
                        #endif
                    }
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
                            .foregroundColor(AppColor.textPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColor.brandAccent.opacity(0.1))
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
                    // ✅ CRITICAL FIX: Usar identificador compuesto para forzar actualización cuando cambia el rating
                    // SwiftUI necesita saber que aunque es el mismo perfume, el contenido cambió
                    ForEach(Array(triedPerfumes.prefix(maxDisplayCount)), id: \.updatedAt) { record in
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
                    .background(AppColor.brandAccent)
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

    // ✅ Perfume lookup: por ID (datos nuevos) o por key (datos legacy) + fuzzy match completo
    private var perfume: Perfume? {
        #if DEBUG
        print("🔍 [TriedPerfumeRow] Looking for perfume: '\(record.perfumeId)'")
        print("   - Metadata index: \(perfumeViewModel.metadataIndex.count) perfumes")
        print("   - Perfumes array: \(perfumeViewModel.perfumes.count) perfumes")
        print("   - Perfume index: \(perfumeViewModel.perfumeIndex.count) items")
        #endif

        // 1. Intentar búsqueda exacta por ID
        if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: record.perfumeId) {
            #if DEBUG
            print("✅ [TriedPerfumeRow] Found '\(record.perfumeId)' in perfumeIndex (exact match)")
            #endif
            return perfume
        }

        // 2. Fallback: buscar por key (datos legacy antes del fix)
        if let perfume = perfumeViewModel.perfumes.first(where: { $0.key == record.perfumeId }) {
            #if DEBUG
            print("✅ [TriedPerfumeRow] Found '\(record.perfumeId)' in perfumes array (exact match)")
            #endif
            return perfume
        }

        // 3. ✅ FUZZY MATCH COMPLETO: Intentar todas las variantes sin prefijos (igual que WishListRowView)
        // Ejemplo: "lattafa_khamrah" → ["khamrah"]
        // Ejemplo: "le_labo_santal_33" → ["labo_santal_33", "santal_33", "33"]
        let components = record.perfumeId.split(separator: "_")

        // Intentar todas las posibles combinaciones quitando prefijos progresivamente
        for startIndex in 1..<components.count {
            let keyVariant = components[startIndex...].joined(separator: "_")

            #if DEBUG
            print("🔍 [TriedPerfumeRow] Trying fuzzy match: '\(record.perfumeId)' → '\(keyVariant)'")
            #endif

            // ✅ BUSCAR EN perfumeIndex primero (perfumes completos ya cargados)
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: keyVariant) {
                #if DEBUG
                print("✅ [TriedPerfumeRow] Found '\(record.perfumeId)' in perfumeIndex: '\(keyVariant)'")
                #endif
                return perfume
            }

            // ✅ BUSCAR EN perfumes array (fallback)
            if let perfume = perfumeViewModel.perfumes.first(where: { $0.key == keyVariant }) {
                #if DEBUG
                print("✅ [TriedPerfumeRow] Found '\(record.perfumeId)' in perfumes array: '\(keyVariant)'")
                #endif
                return perfume
            }

            // ✅ CRITICAL FIX: BUSCAR EN metadataIndex (5587 perfumes) - igual que WishListRowView
            if let metadata = perfumeViewModel.metadataIndex.first(where: { $0.key == keyVariant }) {
                #if DEBUG
                print("✅ [TriedPerfumeRow] Found '\(record.perfumeId)' in metadataIndex: '\(keyVariant)'")
                print("   - Metadata: name=\(metadata.name), brand=\(metadata.brand), key=\(metadata.key)")
                #endif

                // ✅ UNIFIED CRITERION: Construir key en formato "marca_nombre"
                let normalizedBrand = metadata.brand
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let normalizedName = metadata.name
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

                // Crear perfume temporal desde metadata
                let perfume = Perfume(
                    id: metadata.id,
                    name: metadata.name,
                    brand: metadata.brand,
                    brandName: nil,
                    key: unifiedKey,  // ✅ UNIFIED CRITERION: "marca_nombre"
                    family: metadata.family,
                    subfamilies: metadata.subfamilies ?? [],
                    topNotes: [],
                    heartNotes: [],
                    baseNotes: [],
                    projection: "",
                    intensity: "",
                    duration: "",
                    recommendedSeason: [],
                    associatedPersonalities: [],
                    occasion: [],
                    popularity: metadata.popularity,
                    year: metadata.year,
                    perfumist: nil,
                    imageURL: metadata.imageURL ?? "",
                    description: "",
                    gender: metadata.gender,
                    price: metadata.price,
                    searchTerms: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                return perfume
            }
        }

        #if DEBUG
        print("❌ [TriedPerfumeRow] Perfume '\(record.perfumeId)' NOT FOUND in any source")
        // Sample some keys from metadata to help debug
        let sampleKeys = perfumeViewModel.metadataIndex.prefix(10).map { $0.key }
        print("   Sample metadata keys (first 10): \(sampleKeys)")

        // Search explicitly for the variants we tried
        for startIndex in 1..<components.count {
            let keyVariant = components[startIndex...].joined(separator: "_")
            let exists = perfumeViewModel.metadataIndex.contains(where: { $0.key == keyVariant })
            print("   - '\(keyVariant)' exists in metadata: \(exists)")
        }
        #endif

        return nil
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
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(2)

                        Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.textSecondary)
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
                        .foregroundColor(AppColor.textSecondary)
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
