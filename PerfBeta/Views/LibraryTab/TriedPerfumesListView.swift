import SwiftUI
import Kingfisher
import Sliders
import UIKit

struct TriedPerfumesListView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss

    @StateObject private var filterViewModel: FilterViewModel<TriedPerfumeDisplayItem>

    // ✅ ELIMINADO: Sistema de temas personalizable
    @State private var combinedDisplayItems: [TriedPerfumeDisplayItem] = []
    @State private var filteredAndSortedDisplayItems: [TriedPerfumeDisplayItem] = []
    @State private var selectedDisplayItem: TriedPerfumeDisplayItem? = nil

    private let shareService = FragranceLibraryShareService()

    init(familyViewModel: FamilyViewModel) {
        self._filterViewModel = StateObject(wrappedValue: FilterViewModel(
            configuration: .triedPerfumes(),
            familyViewModel: familyViewModel
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 15) {
                        if filterViewModel.isFilterExpanded {
                            PerfumeFilterView(viewModel: filterViewModel)
                        }
                        filterControlButtons
                        if filteredAndSortedDisplayItems.isEmpty {
                            emptyOrNoResultsView
                        } else {
                            perfumeListView
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                }
            }
        }
        .padding(.bottom, 5)
        .navigationBarHidden(true)
        .onAppear(perform: mapInputAndFilter)
        .onChange(of: userViewModel.triedPerfumes) {
            mapInputAndFilter()
        }
        .onChange(of: filterViewModel.searchText) {
            applyFilters()
        }
        .onChange(of: filterViewModel.selectedFilters) {
            applyFilters()
        }
        .onChange(of: filterViewModel.ratingRange) {
            applyFilters()
        }
        .onChange(of: filterViewModel.perfumePopularityRange) {
            applyFilters()
        }
        .onChange(of: filterViewModel.sortOrder) {
            applyFilters()
        }
        .fullScreenCover(item: $selectedDisplayItem) { displayItem in
            PerfumeLibraryDetailView(
                perfume: displayItem.perfume,
                triedPerfume: displayItem.record
            )
        }
    }

    private var headerView: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.backward").foregroundColor(AppColor.textPrimary).font(.title2) }
                .padding(.trailing, 5)

            Text("Perfumes Probados".uppercased())
                .font(.system(size: 18, weight: .light)).foregroundColor(AppColor.textPrimary).lineLimit(1)

            Spacer()

            Button { Task { await shareTriedPerfumes() } } label: { Image(systemName: "square.and.arrow.up").foregroundColor(AppColor.textPrimary).font(.title2) }
                .padding(.trailing, 8)

            Menu {
                Picker("Ordenar por", selection: $filterViewModel.sortOrder) {
                    ForEach(filterViewModel.configuration.availableSortOrders) { order in
                        Text(order.displayName).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill").foregroundColor(AppColor.textPrimary).font(.title2)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color.clear)
    }

    private var filterControlButtons: some View {
        Button(action: { withAnimation { filterViewModel.isFilterExpanded.toggle() } }) {
            HStack {
                Text(filterViewModel.isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                    .font(.system(size: 14, weight: .thin)).foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if filterViewModel.hasActiveFilters {
                    Button(action: filterViewModel.clearFilters) {
                        Text("Limpiar Filtros").font(.system(size: 14, weight: .thin)).foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // ✅ UNIFIED EMPTY STATES
    private var emptyOrNoResultsView: some View {
        Group {
            if filterViewModel.hasActiveFilters {
                // Filters applied but no results
                EmptyStateView(type: .noFilterResults) {
                    filterViewModel.clearFilters()
                }
            } else {
                // No tried perfumes yet
                EmptyStateView(type: .noTriedPerfumes)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 400)
    }

    private var perfumeListView: some View {
        List {
            ForEach(filteredAndSortedDisplayItems) { item in
                PerfumeCard(
                    perfume: item.perfume,
                    brandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand,
                    style: .row,
                    size: .small,
                    showsRating: true,
                    personalRating: item.personalRating
                ) {
                    #if DEBUG
                    print("Tapped on (Tried): \(item.perfume.name)")
                    #endif
                    selectedDisplayItem = item
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task {
                            await deleteTriedPerfume(item: item)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(height: CGFloat(filteredAndSortedDisplayItems.count) * 80)
    }

    private func mapInputAndFilter() {
        Task {
            // ✅ FIX 1: Cargar brands si está vacío (para mostrar nombres bonitos)
            if brandViewModel.brands.isEmpty {
                #if DEBUG
                print("⚠️ [TriedPerfumes] brandViewModel.brands está vacío, cargando brands...")
                #endif
                await brandViewModel.loadInitialData()
                #if DEBUG
                print("✅ [TriedPerfumes] Brands cargados: \(brandViewModel.brands.count)")
                #endif
            }

            // ✅ FIX 2: Cargar perfumes si perfumeViewModel está vacío
            if perfumeViewModel.perfumes.isEmpty && !userViewModel.triedPerfumes.isEmpty {
                #if DEBUG
                print("⚠️ [TriedPerfumes] perfumeViewModel.perfumes está vacío, cargando perfumes necesarios...")
                #endif
                await loadMissingPerfumes()
            }

            await MainActor.run {
                mapTriedPerfumesToDisplayItems()
                applyFilters()
            }
        }
    }

    /// Carga los perfumes que están en tried perfumes pero no en perfumeViewModel.perfumes
    private func loadMissingPerfumes() async {
        let perfumeIds = Set(userViewModel.triedPerfumes.map { $0.perfumeId })
        let loadedKeys = Set(perfumeViewModel.perfumes.map { $0.key })
        let missingKeys = perfumeIds.subtracting(loadedKeys)

        guard !missingKeys.isEmpty else {
            #if DEBUG
            print("✅ [TriedPerfumes] Todos los perfumes ya están cargados")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [TriedPerfumes] Cargando \(missingKeys.count) perfumes faltantes...")
        #endif

        // Cargar perfumes en paralelo
        await withTaskGroup(of: Perfume?.self) { group in
            for key in missingKeys {
                group.addTask {
                    do {
                        return try await self.perfumeViewModel.perfumeService.fetchPerfume(byKey: key)
                    } catch {
                        #if DEBUG
                        print("❌ [TriedPerfumes] Error cargando perfume \(key): \(error.localizedDescription)")
                        #endif
                        return nil
                    }
                }
            }

            // Agregar perfumes cargados a perfumeViewModel
            for await perfume in group {
                if let perfume = perfume {
                    await MainActor.run {
                        perfumeViewModel.perfumes.append(perfume)
                    }
                }
            }
        }

        #if DEBUG
        print("✅ [TriedPerfumes] Perfumes cargados, total en memoria: \(perfumeViewModel.perfumes.count)")
        #endif
    }

    private func mapTriedPerfumesToDisplayItems() {
        #if DEBUG
        print("Mapeando \(userViewModel.triedPerfumes.count) records a display items...")
        #endif

        combinedDisplayItems = userViewModel.triedPerfumes.compactMap { record -> TriedPerfumeDisplayItem? in
            guard let recordId = record.id else {
                #if DEBUG
                print("Saltando record sin ID: \(record.perfumeId)")
                #endif
                return nil
            }

            // Try to find the perfume in the metadata index
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: record.perfumeId) {
                return TriedPerfumeDisplayItem(id: recordId, record: record, perfume: perfume)
            } else {
                // ⚠️ FALLBACK: Perfume no encontrado en BD - Crear placeholder
                // Esto puede pasar si el perfume se eliminó de Firestore pero el usuario ya lo tenía guardado
                #if DEBUG
                print("⚠️ Perfume '\(record.perfumeId)' no encontrado - creando placeholder")
                #endif
                let placeholderPerfume = Perfume(
                    id: record.perfumeId,
                    name: record.perfumeId.replacingOccurrences(of: "_", with: " ").capitalized,
                    brand: "Desconocido",
                    key: record.perfumeId,
                    family: "Desconocido",
                    subfamilies: [],
                    topNotes: [],
                    heartNotes: [],
                    baseNotes: [],
                    projection: "Desconocido",
                    intensity: "Desconocido",
                    duration: "Desconocido",
                    recommendedSeason: [],
                    associatedPersonalities: [],
                    occasion: [],
                    popularity: 0,
                    year: 0,
                    perfumist: nil,
                    imageURL: "",
                    description: "Perfume no disponible en la base de datos",
                    gender: "Desconocido",
                    price: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                return TriedPerfumeDisplayItem(id: recordId, record: record, perfume: placeholderPerfume)
            }
        }
        #if DEBUG
        print("Mapeo completado. \(combinedDisplayItems.count) display items creados.")
        #endif
    }

    private func applyFilters() {
        #if DEBUG
        print("Aplicando filtros desde la vista...")
        #endif
        filteredAndSortedDisplayItems = filterViewModel.applyFiltersAndSort(
            items: combinedDisplayItems,
            brandViewModel: brandViewModel
        )
        #if DEBUG
        print("Filtros aplicados. Mostrando \(filteredAndSortedDisplayItems.count) items.")
        #endif
    }

    private func shareTriedPerfumes() async {
        let filterInfoAdapter = FilterInfoProviderAdapter(viewModel: filterViewModel, familyViewModel: familyViewModel)

        let shareableItems = filteredAndSortedDisplayItems.map { displayItem in
            ShareablePerfumeItem(
                id: displayItem.id,
                perfume: displayItem.perfume,
                displayRating: displayItem.personalRating,
                ratingType: .personal
            )
        }

        await shareService.share(
            items: shareableItems,
            filterInfoProvider: filterInfoAdapter,
            viewProvider: { itemsInternal, filterInfo in
                return GenericPerfumeShareView(
                    title: "Mis Perfumes Probados Favoritos",
                    items: itemsInternal,
                    selectedFilters: filterInfo.selectedFilters,
                    ratingRange: filterInfo.ratingRange,
                    perfumePopularityRange: filterInfo.perfumePopularityRange,
                    searchText: filterInfo.searchText
                )
                .environmentObject(brandViewModel)
                .environmentObject(familyViewModel)
            },
            textProvider: { count, filterInfo in
                return self.generateTriedPerfumesShareText(count: count, filterInfoAdapter: filterInfo)
            }
        )
    }

    private func generateTriedPerfumesShareText(count: Int, filterInfoAdapter: FilterInfoProviderAdapter<TriedPerfumeDisplayItem>) -> String {
        var baseText = "¡Mira mis \(count) perfumes probados favoritos!"
        var filterDescriptions: [String] = []
        let defaultRatingRange = filterInfoAdapter.viewModel.ratingSliderRange
        let defaultPerfumePopularityRange = filterInfoAdapter.viewModel.perfumePopularitySliderRange

        if let genders = filterInfoAdapter.selectedFilters["Género"], !genders.isEmpty {
            let genderNames = filterInfoAdapter.getGenderNames(keys: genders)
            filterDescriptions.append("de \(genderNames.joined(separator: "/"))")
        }
        if let familiesKeys = filterInfoAdapter.selectedFilters["Familia Olfativa"], !familiesKeys.isEmpty {
            let familyNames = filterInfoAdapter.getFamilyNames(keys: familiesKeys)
            filterDescriptions.append("de la familia \(familyNames.joined(separator: "/"))")
        }
        if let seasons = filterInfoAdapter.selectedFilters["Temporada Recomendada"], !seasons.isEmpty {
            let seasonNames = filterInfoAdapter.getSeasonNames(keys: seasons)
            filterDescriptions.append("para \(seasonNames.joined(separator: "/"))")
        }
        if filterInfoAdapter.viewModel.configuration.showPersonalRatingFilter && filterInfoAdapter.ratingRange != defaultRatingRange {
            filterDescriptions.append("Rating: \(Int(filterInfoAdapter.ratingRange.lowerBound))-\(Int(filterInfoAdapter.ratingRange.upperBound))")
        }
        if filterInfoAdapter.perfumePopularityRange != defaultPerfumePopularityRange {
            filterDescriptions.append("Popularidad: \(Int(filterInfoAdapter.perfumePopularityRange.lowerBound))-\(Int(filterInfoAdapter.perfumePopularityRange.upperBound))")
        }

        if !filterDescriptions.isEmpty {
            baseText += " " + filterDescriptions.joined(separator: ", ") + "."
        } else {
            baseText += "."
        }

        #if DEBUG
        print("Texto generado para compartir Probados (refactorizado): \(baseText)")
        #endif
        return baseText
    }

    // MARK: - Delete Functionality

    private func deleteTriedPerfume(item: TriedPerfumeDisplayItem) async {
        #if DEBUG
        print("🗑️ Eliminando perfume probado: \(item.perfume.name)")
        #endif
        await userViewModel.removeTriedPerfume(perfumeId: item.record.perfumeId)
    }
}
