import SwiftUI
import Kingfisher
import Sliders
import UIKit

struct WishlistListView: View {
    // MARK: - Environment Objects & Bindings
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss

    @Binding var wishlistItemsInput: [WishlistItem]

    // MARK: - State Objects & AppStorage
    @StateObject private var filterViewModel: FilterViewModel<WishlistItemDisplayData>

    // ✅ ELIMINADO: Sistema de temas personalizable
    @State private var combinedDisplayItems: [WishlistItemDisplayData] = []
    @State private var filteredAndSortedDisplayItems: [WishlistItemDisplayData] = []

    @State private var perfumeToShow: Perfume? = nil
    @State private var brandToShow: Brand? = nil

    // MARK: - Properties
    private let shareService = FragranceLibraryShareService()

    // Se mantiene para controlar si onMove/onDelete deben hacer algo
    private var isReorderingAllowed: Bool {
        filterViewModel.sortOrder == .manual && !filterViewModel.hasActiveFilters
    }

    // MARK: - Initializer
    init(wishlistItemsInput: Binding<[WishlistItem]>, familyViewModel: FamilyViewModel) {
        self._wishlistItemsInput = wishlistItemsInput
        self._filterViewModel = StateObject(wrappedValue: FilterViewModel(
            configuration: .wishlist(),
            familyViewModel: familyViewModel
        ))
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView // Header ya no tendrá EditButton

                VStack(spacing: 15) {
                    if filterViewModel.isFilterExpanded {
                        PerfumeFilterView(viewModel: filterViewModel)
                    }
                    filterControlButtons
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 10)

                List {
                    Section {
                        if filteredAndSortedDisplayItems.isEmpty {
                            emptyOrNoResultsView
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        } else {
                            perfumeListView
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.clear)
            }
        }
        .padding(.bottom, 5)
        .navigationBarHidden(true)
        .onAppear(perform: mapInputAndFilter)
        .onChange(of: wishlistItemsInput) {
            mapInputAndFilter()
        }
        .onChange(of: filterViewModel.searchText) {
            applyFilters()
        }
        .onChange(of: filterViewModel.selectedFilters) {
            applyFilters()
        }
        .onChange(of: filterViewModel.perfumePopularityRange) {
            applyFilters()
        }
        .onChange(of: filterViewModel.sortOrder) {
            applyFilters()
        }
        .fullScreenCover(item: $perfumeToShow) { perfume in
            // brandToShow puede ser nil si no se encontró la marca
            // PerfumeDetailView puede funcionar con brand = nil
            PerfumeDetailView(perfume: perfume, brand: brandToShow, profile: nil)
        }
        // Usar la nueva sintaxis. Podemos acceder a perfumeToShow directamente.
        .onChange(of: perfumeToShow) {
            if perfumeToShow == nil {
                brandToShow = nil
            }
        }
        // Usar la nueva sintaxis. Podemos acceder a isReorderingAllowed directamente.
        .onChange(of: isReorderingAllowed) {
            if !isReorderingAllowed {
                // La acción original que tenías aquí (comentada)
                // print("Reordenación/Edición no permitida debido a filtros activos.")
            }
        }
    }

    // MARK: - Private Views
    private var headerView: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.backward").foregroundColor(Color("textoPrincipal")).font(.title2) }
            .padding(.trailing, 5)

            Text("LISTA DE DESEOS")
                .font(.system(size: 18, weight: .light)).foregroundColor(Color("textoPrincipal")).lineLimit(1)

            Spacer()

            Button { Task { await shareWishlist() } } label: { Image(systemName: "square.and.arrow.up").foregroundColor(Color("textoPrincipal")).font(.title2) }
            .padding(.trailing, 8)

            Menu {
                Picker("Ordenar por", selection: $filterViewModel.sortOrder) {
                    ForEach(filterViewModel.configuration.availableSortOrders) { order in
                         Text(order.displayName).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill").foregroundColor(Color("textoPrincipal")).font(.title2)
            }
        }
        .padding(.horizontal, 25)
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

    private var perfumeListView: some View {
        ForEach(filteredAndSortedDisplayItems) { item in
            perfumeRow(item: item)
                .listRowInsets(EdgeInsets(top: 0, leading: 25, bottom: 0, trailing: 25))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        // Solo permite onMove si isReorderingAllowed es true
        .onMove(perform: isReorderingAllowed ? moveWishlistItem : nil)
        // Solo permite onDelete si isReorderingAllowed es true (o siempre si quieres permitir borrar con filtros)
        .onDelete(perform: isReorderingAllowed ? deleteWishlistItemFromList : nil)
    }
    
    @ViewBuilder
    // ✅ UNIFIED EMPTY STATES
    private var emptyOrNoResultsView: some View {
        Group {
            if filterViewModel.hasActiveFilters {
                // Filters applied but no results
                EmptyStateView(type: .noFilterResults) {
                    filterViewModel.clearFilters()
                }
            } else {
                // Empty wishlist
                EmptyStateView(type: .noWishlist)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(minHeight: 400)
    }

    private func perfumeRow(item: WishlistItemDisplayData) -> some View {
        PerfumeCard(
            perfume: item.perfume,
            brandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand,
            style: .row,
            size: .small,
            showsRating: true
        ) {
            Task {
                await loadAndShowDetail(
                    perfumeKey: item.perfume.key,
                    brandKey: item.perfume.brand
                )
            }
        }
    }


    // MARK: - Data Handling & Filtering (sin cambios)
     private func mapInputAndFilter() {
        Task {
            // ✅ FIX 1: Cargar brands si está vacío (para mostrar nombres bonitos)
            if brandViewModel.brands.isEmpty {
                print("⚠️ [Wishlist] brandViewModel.brands está vacío, cargando brands...")
                await brandViewModel.loadInitialData()
                print("✅ [Wishlist] Brands cargados: \(brandViewModel.brands.count)")
            }

            // ✅ FIX 2: Cargar perfumes si perfumeViewModel está vacío
            if perfumeViewModel.perfumes.isEmpty && !wishlistItemsInput.isEmpty {
                print("⚠️ [Wishlist] perfumeViewModel.perfumes está vacío, cargando perfumes necesarios...")
                await loadMissingPerfumes()
            }

            await MainActor.run {
                mapWishlistItemsToDisplayItems()
                applyFilters()
            }
        }
    }

    /// Carga los perfumes que están en la wishlist pero no en perfumeViewModel.perfumes
    private func loadMissingPerfumes() async {
        let perfumeKeys = Set(wishlistItemsInput.map { $0.perfumeId })
        let loadedKeys = Set(perfumeViewModel.perfumes.map { $0.id })
        let missingKeys = perfumeKeys.subtracting(loadedKeys)

        guard !missingKeys.isEmpty else {
            print("✅ [Wishlist] Todos los perfumes ya están cargados")
            return
        }

        print("🔄 [Wishlist] Cargando \(missingKeys.count) perfumes faltantes...")

        // Cargar perfumes en paralelo usando IDs
        await withTaskGroup(of: Perfume?.self) { group in
            for id in missingKeys {
                group.addTask {
                    do {
                        return try await self.perfumeViewModel.perfumeService.fetchPerfume(id: id)
                    } catch {
                        print("❌ [Wishlist] Error cargando perfume \(id): \(error.localizedDescription)")
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

        print("✅ [Wishlist] Perfumes cargados, total en memoria: \(perfumeViewModel.perfumes.count)")
    }

    private func mapWishlistItemsToDisplayItems() {
        print("Mapeando Wishlist...")
        // ✅ FIX: Use perfume.id (document ID) to match wishlistItem.perfumeId
        let perfumeDict = perfumeViewModel.perfumes.reduce(into: [String: Perfume]()) { dict, perfume in
            if dict[perfume.id] == nil {
                dict[perfume.id] = perfume
            }
        }

        combinedDisplayItems = wishlistItemsInput.compactMap { wishlistItem -> WishlistItemDisplayData? in
            guard let itemId = wishlistItem.id else {
                print("⚠️ [Wishlist] WishlistItem sin ID: \(wishlistItem.perfumeId)")
                return nil
            }

            guard let perfume = perfumeDict[wishlistItem.perfumeId] else {
                print("⚠️ [Wishlist] Perfume no encontrado para id: \(wishlistItem.perfumeId)")
                return nil
            }

            return WishlistItemDisplayData(id: itemId, wishlistItem: wishlistItem, perfume: perfume)
        }

        print("Mapeo Wishlist completado: \(combinedDisplayItems.count) items de \(wishlistItemsInput.count) totales.")
    }

    private func applyFilters() { // Sin cambios
        print("Aplicando filtros/orden a Wishlist...")
        filteredAndSortedDisplayItems = filterViewModel.applyFiltersAndSort(
            items: combinedDisplayItems,
            brandViewModel: brandViewModel
        )
        print("Wishlist filtrada/ordenada: \(filteredAndSortedDisplayItems.count) items.")
    }


    // MARK: - Actions
    // Ajustar onMove y onDelete para usar la condición
    private func moveWishlistItem(from source: IndexSet, to destination: Int) {
        // La condición ya está en el modificador .onMove
        // guard isReorderingAllowed else { return } // Doble check opcional
        print("Moviendo item(s) de \(source) a \(destination)")
        wishlistItemsInput.move(fromOffsets: source, toOffset: destination)
        // ⚠️ TODO: Reimplement wishlist reordering with new WishlistItem model (no orderIndex field)
        // Task {
        //     await userViewModel.updateWishlistOrder(orderedPerfumes: wishlistItemsInput)
        //     print("Orden de la Wishlist actualizado en el backend.")
        // }
    }

    private func deleteWishlistItemFromList(at offsets: IndexSet) {
        let itemsDataToDelete = offsets.map { filteredAndSortedDisplayItems[$0] }
        let idsToDelete = Set(itemsDataToDelete.map { $0.id })
        
        wishlistItemsInput.removeAll { wishlistItem in
            guard let itemId = wishlistItem.id else { return false }
            return idsToDelete.contains(itemId)
        }
        print("✅ Eliminación optimista local realizada para IDs: \(idsToDelete)")
        
        for itemData in itemsDataToDelete {
            Task {
                // ✅ REFACTOR: Nueva API usa perfumeId directamente
                await userViewModel.removeFromWishlist(perfumeId: itemData.wishlistItem.perfumeId)
                print("✅ Solicitud de eliminación enviada a Firestore para: \(itemData.wishlistItem.perfumeId)")
            }
        }
    }

    // MARK: - Actions
    private func shareWishlist() async {
        // 1. Crear el adaptador (igual que antes)
        let filterInfoAdapter = FilterInfoProviderAdapter(viewModel: filterViewModel, familyViewModel: familyViewModel)

        // 2. Mapear a ShareablePerfumeItem (igual que antes)
        let shareableItems = filteredAndSortedDisplayItems.map { displayItem in
            ShareablePerfumeItem(
                id: displayItem.id,
                perfume: displayItem.perfume,
                // ✅ REFACTOR: WishlistItem no tiene rating (es lista de deseos, no probados)
                displayRating: nil,
                ratingType: .interest
            )
        }

        // 3. Llamar a shareService.share
        await shareService.share(
            items: shareableItems,          // Los items mapeados
            filterInfoProvider: filterInfoAdapter, // El adaptador original

            // --- Clausura viewProvider ---
            // 'filterInfo' aquí ya es del tipo FilterInfoProviderAdapter<WishlistItemDisplayData>
            viewProvider: { itemsInternal, filterInfo in
                // NO necesitas: let adapter = filterInfo as! ...
                return GenericPerfumeShareView(
                    title: "Mi Lista de Deseos",
                    items: itemsInternal, // Los shareableItems
                    selectedFilters: filterInfo.selectedFilters, // Accede directamente a filterInfo
                    ratingRange: nil,
                    perfumePopularityRange: filterInfo.perfumePopularityRange, // Accede directamente a filterInfo
                    searchText: filterInfo.searchText // Accede directamente a filterInfo
                )
                .environmentObject(brandViewModel)
                .environmentObject(familyViewModel)
            },

            // --- Clausura textProvider ---
            // 'filterInfo' aquí también ya es del tipo FilterInfoProviderAdapter<WishlistItemDisplayData>
            textProvider: { count, filterInfo in
                // NO necesitas: let adapter = filterInfo as! ...
                // Llama a generateWishlistText pasando 'filterInfo' directamente
                return self.generateWishlistText(count: count, filterInfoAdapter: filterInfo)
            }
        )
    }

    // La firma de esta función ya era correcta, recibe el tipo específico.
    // No necesita cambios internos, solo confirmar que la llamada desde textProvider le pasa
    // el 'filterInfo' directamente.
    private func generateWishlistText(count: Int, filterInfoAdapter: FilterInfoProviderAdapter<WishlistItemDisplayData>) -> String {
        var baseText = "¡Mira mis \(count) perfumes favoritos de mi lista de deseos!"
        var filterDescriptions: [String] = []
        let defaultPerfumePopularityRange = filterInfoAdapter.viewModel.perfumePopularitySliderRange

        // La lógica interna usa filterInfoAdapter directamente, lo cual está bien.
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
        if filterInfoAdapter.perfumePopularityRange != defaultPerfumePopularityRange {
            filterDescriptions.append("Popularidad: \(Int(filterInfoAdapter.perfumePopularityRange.lowerBound))-\(Int(filterInfoAdapter.perfumePopularityRange.upperBound))")
        }

        if !filterDescriptions.isEmpty {
            baseText += " " + filterDescriptions.joined(separator: ", ") + "."
        } else {
            baseText += "."
        }

        print("Texto generado para compartir Wishlist: \(baseText)")
        return baseText
    }

    func loadAndShowDetail(perfumeKey: String, brandKey: String) async { // Sin cambios
        perfumeToShow = nil
        brandToShow = nil
        do {
            print("Cargando detalle para: PerfumeKey=\(perfumeKey), BrandKey=\(brandKey)")
            async let perfumeTask = perfumeViewModel.getPerfume(byKey: perfumeKey)
            async let brandTask = brandViewModel.getBrand(byKey: brandKey)
            let fetchedPerfume = try await perfumeTask
            let fetchedBrand = await brandTask

            if let perfume = fetchedPerfume, let brand = fetchedBrand {
                print("Detalle cargado: Perfume=\(perfume.name), Marca=\(brand.name)")
                brandToShow = brand
                perfumeToShow = perfume
            } else {
                print("Error: No se pudo cargar el perfume (\(fetchedPerfume != nil)) o la marca (\(fetchedBrand != nil)).")
            }
        } catch {
            print("Error al cargar detalles del perfume/marca: \(error)")
        }
    }

}
