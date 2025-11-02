import SwiftUI
import Combine
import Kingfisher

// MARK: - AddPerfumeStep1View
struct AddPerfumeStep1View: View {
    @Binding var selectedPerfume: Perfume?
    @ObservedObject var perfumeViewModel: PerfumeViewModel
    @ObservedObject var brandViewModel: BrandViewModel
    @Binding var onboardingStep: Int
    var initialSelectedPerfume: Perfume? = nil
    @Binding var isAddingPerfume: Bool
    @Binding var showingEvaluationOnboarding: Bool

    @State private var searchText: String = ""
    @State private var filteredResults: [Perfume] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil
    private let maxResults = 50  // Limitar resultados para mejor performance
    private let debounceDelay: TimeInterval = 0.3  // Delay para debouncing

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.body)

                    TextField("Buscar perfume o marca...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            // Buscar cuando el usuario presiona Enter
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            filteredResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Content
            if perfumeViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Cargando perfumes...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if searchText.isEmpty {
                // ✅ EmptyState con instrucciones cuando no hay búsqueda
                emptySearchState
            } else if isSearching {
                // Buscando...
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Buscando...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if filteredResults.isEmpty {
                // ✅ No results state
                noResultsState
            } else {
                // ✅ Results list con autocomplete visual
                resultsListView
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            // Cancelar búsqueda previa
            searchTask?.cancel()

            if newValue.isEmpty {
                filteredResults = []
                isSearching = false
                return
            }

            // Debouncing: Esperar 0.3s antes de buscar
            searchTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))

                // Verificar si la tarea no fue cancelada
                if !Task.isCancelled {
                    performSearch()
                }
            }
        }
        .onAppear {
            if let initialPerfume = initialSelectedPerfume {
                selectedPerfume = initialPerfume
            }
        }
    }

    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("Busca tu perfume")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    Text("Escribe el nombre del perfume o la marca en el buscador.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Por ejemplo: \"Sauvage\", \"Dior\", \"Acqua di Gio\"")
                        .font(.callout)
                        .foregroundColor(.secondary.opacity(0.8))
                        .italic()
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Results State
    private var noResultsState: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("No encontramos resultados")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Intenta con otro nombre o marca")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results List
    private var resultsListView: some View {
        VStack(spacing: 0) {
            // Autocomplete suggestion header
            if !searchText.isEmpty && filteredResults.count > 0 {
                HStack {
                    Text("\(filteredResults.count) resultado\(filteredResults.count == 1 ? "" : "s") encontrado\(filteredResults.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredResults, id: \.id) { perfume in
                        NavigationLink(destination: AddPerfumeStep2View(
                            selectedPerfume: perfume,
                            isAddingPerfume: $isAddingPerfume,
                            showingEvaluationOnboarding: $showingEvaluationOnboarding
                        )) {
                            PerfumeSearchResultRow(
                                perfume: perfume,
                                brandViewModel: brandViewModel,
                                perfumeViewModel: perfumeViewModel,
                                searchText: searchText
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    // MARK: - Search Function
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            filteredResults = []
            return
        }

        // Ejecutar búsqueda de forma asíncrona para no bloquear la UI
        Task {
            // Solo mostrar indicador de búsqueda si tarda más de 0.1s
            let showLoadingTask = Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                if !Task.isCancelled {
                    await MainActor.run {
                        isSearching = true
                    }
                }
            }

            // ✅ FIX: Usar metadataIndex para buscar en TODOS los perfumes
            let allMetadata = perfumeViewModel.metadataIndex

            // ✅ Crear diccionario de perfumes completos para obtener imageURL
            let perfumesDict = perfumeViewModel.perfumes.reduce(into: [String: Perfume]()) { dict, perfume in
                dict[perfume.key] = perfume
            }

            // Realizar búsqueda en background thread
            let results = await Task.detached(priority: .userInitiated) {
                allMetadata.filter { metadata in
                    metadata.name.localizedCaseInsensitiveContains(query) ||
                    metadata.brand.localizedCaseInsensitiveContains(query)
                }
                .prefix(maxResults)  // Limitar resultados para mejor performance
                .map { metadata in
                    // ✅ Buscar imageURL en perfumes completos si existe
                    let imageURL = perfumesDict[metadata.key]?.imageURL ?? ""

                    // Convertir PerfumeMetadata a Perfume ligero para UI
                    return Perfume(
                        id: metadata.id ?? metadata.key,
                        name: metadata.name,
                        brand: metadata.brand,
                        key: metadata.key,
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
                        imageURL: imageURL,
                        description: "",
                        gender: metadata.gender,
                        price: metadata.price,
                        createdAt: nil,
                        updatedAt: metadata.updatedAt
                    )
                }
            }.value

            // Cancelar tarea de loading si aún no se mostró
            showLoadingTask.cancel()

            // Actualizar UI en main thread
            await MainActor.run {
                // Solo actualizar si el query aún es el mismo
                if query == searchText.trimmingCharacters(in: .whitespacesAndNewlines) {
                    filteredResults = Array(results)
                }
                isSearching = false
            }
        }
    }
}

// MARK: - Perfume Search Result Row
struct PerfumeSearchResultRow: View {
    let perfume: Perfume
    @ObservedObject var brandViewModel: BrandViewModel
    @ObservedObject var perfumeViewModel: PerfumeViewModel
    let searchText: String

    @State private var fullPerfume: Perfume?
    @State private var isLoadingImage = false

    var body: some View {
        HStack(spacing: 12) {
            // ✅ Imagen con carga on-demand en background
            KFImage((fullPerfume?.imageURL ?? perfume.imageURL).flatMap { URL(string: $0) })
                .placeholder {
                    ZStack {
                        Color(.systemGray6)
                        if isLoadingImage {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .cacheMemoryOnly(false) // Use disk cache
                .diskCacheExpiration(.never) // Permanent cache
                .onSuccess { result in
                    print("✅ [Search] Image loaded for: \(perfume.name) from \(result.cacheType)")
                }
                .onFailure { error in
                    print("⚠️ [Search] Image failed for: \(perfume.name) - \(error.localizedDescription)")
                }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .task {
                    // ✅ Cargar perfume completo on-demand si no tiene imageURL
                    await loadFullPerfumeIfNeeded()
                }

            // Info del perfume
            VStack(alignment: .leading, spacing: 4) {
                // Nombre con highlight del texto buscado
                Text(perfume.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !perfume.family.isEmpty {
                    Text(perfume.family)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
    }

    // MARK: - Load Full Perfume On-Demand
    private func loadFullPerfumeIfNeeded() async {
        // Si ya tiene imageURL, no hacer nada
        guard perfume.imageURL?.isEmpty != false else {
            return
        }

        // Si ya se está cargando, evitar duplicados
        guard !isLoadingImage else {
            return
        }

        isLoadingImage = true
        print("🔄 [Search] Loading full perfume for: \(perfume.name)")

        do {
            // Cargar perfume completo desde Firestore
            if let loadedPerfume = try await perfumeViewModel.loadPerfumeByKey(perfume.key) {
                // ✅ Actualizar estado local - trigger re-render con imageURL
                await MainActor.run {
                    fullPerfume = loadedPerfume
                    isLoadingImage = false
                }
                print("✅ [Search] Full perfume loaded: \(perfume.name), imageURL: \(loadedPerfume.imageURL ?? "none")")
            } else {
                await MainActor.run {
                    isLoadingImage = false
                }
                print("⚠️ [Search] Perfume not found: \(perfume.key)")
            }
        } catch {
            await MainActor.run {
                isLoadingImage = false
            }
            print("❌ [Search] Error loading perfume: \(error)")
        }
    }
}
