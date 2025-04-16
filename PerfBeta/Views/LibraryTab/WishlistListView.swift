import SwiftUI
import Kingfisher
import Sliders
import UIKit

struct WishlistItemDisplayData: Identifiable {
    let id: String
    let wishlistItem: WishlistItem
    let perfume: Perfume
}

struct WishlistListView: View, FilterInformationProvider {
    @Binding var wishlistItemsInput: [WishlistItem]
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.editMode) private var editMode

    private let shareService = ShareService()

    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    @State var searchText = ""
    @State var selectedFilters: [String: [String]] = [:]
    @State private var isFilterExpanded = false
    @State private var genreExpanded: Bool = false
    @State private var familyExpanded: Bool = false
    @State private var seasonExpanded: Bool = false
    @State private var projectionExpanded: Bool = false
    @State private var durationExpanded: Bool = false
    @State private var priceExpanded: Bool = false
    @State private var perfumePopularityExpanded: Bool = false

    let perfumePopularitySliderRange: ClosedRange<Double> = 0...10
    @State var perfumePopularityRange: ClosedRange<Double> = 0...10

    @State private var sortOrder: SortOrder = .manual

    enum SortOrder: Identifiable {
        case manual, nameAscending, nameDescending, popularityAscending, popularityDescending, none
        var id: Self { self }
    }

    @State private var combinedDisplayItems: [WishlistItemDisplayData] = []
    @State private var filteredAndSortedDisplayItems: [WishlistItemDisplayData] = []

    @State private var perfumeToShow: Perfume? = nil
    @State private var brandToShow: Brand? = nil

    private var isReorderingAllowed: Bool {
        searchText.isEmpty && selectedFilters.isEmpty && sortOrder == .manual
    }

    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: selectedGradientPreset)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                List {
                    Section {
                        // Filtros y Búsqueda ahora dentro de una sección de List
                        VStack(spacing: 15) {
                            if isFilterExpanded {
                                searchSection
                                filterSection
                            }
                            Button(action: { withAnimation { isFilterExpanded.toggle() } }) {
                                HStack {
                                    Text(isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                                        .font(.system(size: 14, weight: .thin)).foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if !selectedFilters.isEmpty || !searchText.isEmpty || perfumePopularityRange != perfumePopularitySliderRange {
                                        Button(action: clearFilters) {
                                            Text("Limpiar Filtros").font(.system(size: 14, weight: .thin)).foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.vertical, 8) // Mantiene padding vertical
                            }
                        }
                        .padding(.horizontal, 25) // Reaplica padding horizontal
                        .listRowInsets(EdgeInsets()) // Quita insets de List
                        .listRowSeparator(.hidden) // Oculta separador
                        .listRowBackground(Color.clear) // Fondo transparente
                    } // Fin Section Filtros

                    Section {
                        if filteredAndSortedDisplayItems.isEmpty {
                           emptyOrNoResultsView
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(filteredAndSortedDisplayItems) { item in
                                perfumeRow(item: item)
                            }
                            .onMove(perform: moveWishlistItem)
                            .onDelete(perform: deleteWishlistItemFromList)
                        }
                    } // Fin Section Perfumes
                } // Fin List
                .listStyle(.plain)
                .environment(\.editMode, editMode)
                .background(Color.clear) // Fondo general de la lista
            }
        }
        .padding(.bottom, 5)
        .navigationBarHidden(true)
        .onAppear(perform: mapWishlistItemsToDisplayItems)
        .onChange(of: wishlistItemsInput, perform: { _ in mapWishlistItemsToDisplayItems() })
        .onChange(of: sortOrder, perform: { _ in applyFiltersAndSort() })
        .onChange(of: selectedFilters, perform: { _ in applyFiltersAndSort() })
        .onChange(of: perfumePopularityRange, perform: { _ in applyFiltersAndSort() })
        .onChange(of: searchText, perform: { _ in applyFiltersAndSort() })
        .fullScreenCover(item: $perfumeToShow) { perfume in
            if let brand = brandToShow {
                PerfumeDetailView(perfume: perfume, brand: brand, profile: nil)
            } else {
                ProgressView()
            }
        }
        .onChange(of: perfumeToShow) { newValue in
            if newValue == nil { brandToShow = nil }
        }
        .onChange(of: isReorderingAllowed) { allowed in
            if !allowed && editMode?.wrappedValue.isEditing == true {
                editMode?.wrappedValue = .inactive
                print("Saliendo del modo edición porque los filtros/orden han cambiado.")
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.backward").foregroundColor(Color("textoPrincipal")).font(.title2) }
            .padding(.trailing, 5)

            Text("LISTA DE DESEOS")
                .font(.system(size: 18, weight: .light)).foregroundColor(Color("textoPrincipal")).lineLimit(1)

            Spacer()

            if isReorderingAllowed {
                EditButton()
                    .padding(.trailing, 8)
            }

            Button { Task { await shareWishlist() } } label: { Image(systemName: "square.and.arrow.up").foregroundColor(Color("textoPrincipal")).font(.title2) }
            .padding(.trailing, 8)

            Menu {
                Picker("Ordenar por", selection: $sortOrder) {
                    Text("Orden Manual").tag(SortOrder.manual)
                    Divider()
                    Text("Popularidad (Mayor a Menor)").tag(SortOrder.popularityDescending)
                    Text("Popularidad (Menor a Mayor)").tag(SortOrder.popularityAscending)
                    Divider()
                    Text("Nombre (A - Z)").tag(SortOrder.nameAscending)
                    Text("Nombre (Z - A)").tag(SortOrder.nameDescending)
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

    private var searchSection: some View {
        TextField("Buscar perfume o marca...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.bottom, 8)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterCategoryAccordion(title: "Género", options: Gender.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }, expanded: $genreExpanded)
            filterCategoryAccordion(title: "Familia Olfativa", options: familyViewModel.familias.map { FilterKeyPair(id: $0.key, key: $0.key, name: $0.name) }, expanded: $familyExpanded)
            filterCategoryAccordion(title: "Temporada Recomendada", options: Season.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }, expanded: $seasonExpanded)
            filterCategoryAccordion(title: "Proyección", options: Projection.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }, expanded: $projectionExpanded)
            filterCategoryAccordion(title: "Duración", options: Duration.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }, expanded: $durationExpanded)
            filterCategoryAccordion(title: "Precio", options: Price.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }, expanded: $priceExpanded)
            filterPerfumePopularitySliderAccordion()
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var emptyOrNoResultsView: some View {
        if !searchText.isEmpty || !selectedFilters.isEmpty || perfumePopularityRange != perfumePopularitySliderRange {
            Text("No se encontraron perfumes con los filtros seleccionados.")
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
                .multilineTextAlignment(.center)
        } else {
             emptyListView
        }
    }

    private var emptyListView: some View {
        Text("Tu lista de deseos está vacía.")
            .font(.title3)
            .foregroundColor(Color.gray)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(minHeight: 200)
    }

    private func perfumeRow(item: WishlistItemDisplayData) -> some View {
         let rowData = PerfumeRowDisplayData(
             id: item.id,
             perfumeKey: item.perfume.key,
             brandKey: item.perfume.brand,
             imageURL: item.perfume.imageURL,
             initialPerfumeName: item.perfume.name,
             initialBrandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name,
             personalRating: nil,
             generalRating: item.wishlistItem.rating,
             onTapAction: {
                 Task {
                    await loadAndShowDetail(
                         perfumeKey: item.perfume.key,
                         brandKey: item.perfume.brand
                    )
                 }
             }
         )
         return VStack(alignment: .leading, spacing: 0) {
             GenericPerfumeRowView(data: rowData)
         }
         .listRowInsets(EdgeInsets(top: 5, leading: 25, bottom: 5, trailing: 25)) // Reaplica padding horizontal + vertical
         .listRowSeparator(.hidden) // Oculta separadores si prefieres los manuales
         .listRowBackground(Color.clear) // Fondo transparente para la fila
         // Puedes añadir un Divider manual aquí si ocultaste el de List
         // if item.id != filteredAndSortedDisplayItems.last?.id {
         //     Divider().padding(.leading, 90) // Ajusta el padding
         // }
    }

    private func mapWishlistItemsToDisplayItems() {
        print("Mapeando Wishlist...")
        let perfumeDict = Dictionary(uniqueKeysWithValues: perfumeViewModel.perfumes.map { ($0.key, $0) })
        combinedDisplayItems = wishlistItemsInput.compactMap { wishlistItem -> WishlistItemDisplayData? in
            guard let itemId = wishlistItem.id, let perfume = perfumeDict[wishlistItem.perfumeKey] else { return nil }
            return WishlistItemDisplayData(id: itemId, wishlistItem: wishlistItem, perfume: perfume)
        }
        applyFiltersAndSort()
    }

    private func applyFiltersAndSort() {
        print("Aplicando filtros/orden a Wishlist...")
        var workingList = combinedDisplayItems

        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            workingList = workingList.filter { item in
                item.perfume.name.lowercased().contains(lowercasedSearch) ||
                (brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand).lowercased().contains(lowercasedSearch)
            }
        }

         workingList = workingList.filter { item in
             let popularityScore = item.perfume.popularity / 10.0
             return popularityScore >= perfumePopularityRange.lowerBound && popularityScore <= perfumePopularityRange.upperBound
        }

        if !selectedFilters.isEmpty {
            workingList = workingList.filter { item in
                let perfume = item.perfume
                let matchesGender = selectedFilters["Género"]?.isEmpty ?? true || selectedFilters["Género"]!.contains(perfume.gender)
                let matchesFamily = selectedFilters["Familia Olfativa"]?.isEmpty ?? true || selectedFilters["Familia Olfativa"]!.contains(perfume.family)
                let matchesSeason = selectedFilters["Temporada Recomendada"]?.isEmpty ?? true || !Set(selectedFilters["Temporada Recomendada"]!).intersection(Set(perfume.recommendedSeason.compactMap { Season(rawValue: $0)?.rawValue })).isEmpty
                let matchesProjection = selectedFilters["Proyección"]?.isEmpty ?? true || selectedFilters["Proyección"]!.contains(perfume.projection)
                let matchesDuration = selectedFilters["Duración"]?.isEmpty ?? true || selectedFilters["Duración"]!.contains(perfume.duration)
                let matchesPrice = selectedFilters["Precio"]?.isEmpty ?? true || selectedFilters["Precio"]!.contains(perfume.price ?? "")
                return matchesGender && matchesFamily && matchesSeason && matchesProjection && matchesDuration && matchesPrice
            }
        }

        if sortOrder != .manual {
            workingList = sortDisplayItems(items: workingList, sortOrder: sortOrder)
        } else {
             // Si es manual, intenta mantener el orden de combinedDisplayItems (que refleja wishlistItemsInput)
             // Mapea los IDs de la workingList (filtrada) para mantener el orden correcto
             let filteredIDs = Set(workingList.map { $0.id })
             workingList = combinedDisplayItems.filter { filteredIDs.contains($0.id) }
        }


        filteredAndSortedDisplayItems = workingList
        print("Wishlist filtrada/ordenada: \(filteredAndSortedDisplayItems.count) items.")

        if !isReorderingAllowed && editMode?.wrappedValue.isEditing == true {
             editMode?.wrappedValue = .inactive
        }
    }

    private func clearFilters() {
        searchText = ""
        selectedFilters.removeAll()
        genreExpanded = false; familyExpanded = false; seasonExpanded = false;
        projectionExpanded = false; durationExpanded = false; priceExpanded = false;
        perfumePopularityExpanded = false;
        perfumePopularityRange = perfumePopularitySliderRange
        sortOrder = .manual
        applyFiltersAndSort()
    }

    private func toggleFilter(category: String, option: String) {
        if selectedFilters[category]?.contains(option) == true {
            selectedFilters[category]?.removeAll { $0 == option }
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            selectedFilters[category, default: []].append(option)
        }
        applyFiltersAndSort() // Llama aquí o usa .onChange
    }

    private func isSelected(category: String, option: String) -> Bool {
        selectedFilters[category]?.contains(option) == true
    }

     private func sortDisplayItems(items: [WishlistItemDisplayData], sortOrder: SortOrder) -> [WishlistItemDisplayData] {
         guard sortOrder != .manual else { return items }

         switch sortOrder {
         case .popularityAscending: return items.sorted { $0.perfume.popularity < $1.perfume.popularity }
         case .popularityDescending: return items.sorted { $0.perfume.popularity > $1.perfume.popularity }
         case .nameAscending: return items.sorted { $0.perfume.name < $1.perfume.name }
         case .nameDescending: return items.sorted { $0.perfume.name > $1.perfume.name }
         case .manual, .none: return items
         }
     }

    private func moveWishlistItem(from source: IndexSet, to destination: Int) {
        guard isReorderingAllowed else {
             print("Reordenación no permitida debido a filtros o orden activo.")
             return
        }
        print("Moviendo item(s) de \(source) a \(destination)")
        wishlistItemsInput.move(fromOffsets: source, toOffset: destination)
        Task {
            await userViewModel.updateWishlistOrder(userId: "testUserId", orderedPerfumes: wishlistItemsInput)
            print("Orden de la Wishlist actualizado en el backend.")
        }
    }

    private func deleteWishlistItemFromList(at offsets: IndexSet) {
         let itemsDataToDelete = offsets.map { filteredAndSortedDisplayItems[$0] }
         for itemData in itemsDataToDelete {
             Task {
                 do {
                     try await userViewModel.removeFromWishlist(userId: "testUserId", wishlistItem: itemData.wishlistItem)
                     print("Solicitud de eliminación enviada para: \(itemData.wishlistItem.perfumeKey)")
                 } catch {
                     print("Error al eliminar el wishlistItem con key: \(itemData.wishlistItem.perfumeKey). Error: \(error)")
                 }
             }
         }
    }

    private func shareWishlist() async {
         await shareService.share(
            items: filteredAndSortedDisplayItems,
            filterInfo: self,
            viewProvider: { items, filterInfoProvider in
                return TopWishlistShareView(
                    items: items,
                    selectedFilters: filterInfoProvider.selectedFilters,
                    perfumePopularityRange: filterInfoProvider.perfumePopularityRange,
                    searchText: filterInfoProvider.searchText
                )
                .environmentObject(brandViewModel)
                .environmentObject(familyViewModel)
            },
            textProvider: { count, filterInfoProvider in
                 return self.generateWishlistText(count: count, filterInfo: filterInfoProvider)
            }
        )
    }
    private func generateWishlistText(count: Int, filterInfo: FilterInformationProvider) -> String {
        var baseText = "¡Mira mis \(count) perfumes favoritos de mi lista de deseos!"
        var filterDescriptions: [String] = []
        let defaultPerfumePopularityRange: ClosedRange<Double> = 0...10

        if let genders = filterInfo.selectedFilters["Género"], !genders.isEmpty {
            let genderNames = genders.compactMap { Gender(rawValue: $0)?.displayName ?? $0 }
            filterDescriptions.append("de \(genderNames.joined(separator: "/"))")
        }
         if let familiesKeys = filterInfo.selectedFilters["Familia Olfativa"], !familiesKeys.isEmpty {
             let familyNames = familiesKeys.compactMap { key in familyViewModel.familias.first { $0.key == key }?.name ?? key }
             filterDescriptions.append("de la familia \(familyNames.joined(separator: "/"))")
         }
        if let seasons = filterInfo.selectedFilters["Temporada Recomendada"], !seasons.isEmpty {
            let seasonNames = seasons.compactMap { Season(rawValue: $0)?.displayName ?? $0 }
            filterDescriptions.append("para \(seasonNames.joined(separator: "/"))")
        }
        if filterInfo.perfumePopularityRange != defaultPerfumePopularityRange {
            filterDescriptions.append("Popularidad: \(Int(filterInfo.perfumePopularityRange.lowerBound))-\(Int(filterInfo.perfumePopularityRange.upperBound))")
        }

        if !filterDescriptions.isEmpty { baseText += " " + filterDescriptions.joined(separator: ", ") + "." }
        else { baseText += "." }

        print("Texto generado para compartir Wishlist: \(baseText)")
        return baseText
    }
    func loadAndShowDetail(perfumeKey: String, brandKey: String) async {
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
            } else { print("Error: No se pudo cargar el perfume (\(fetchedPerfume != nil)) o la marca (\(fetchedBrand != nil)).") }
        } catch { print("Error al cargar detalles del perfume/marca: \(error)") }
    }

    private func filterCategoryAccordion(title: String, options: [FilterKeyPair], expanded: Binding<Bool>) -> some View {
        Group {
            if options.isEmpty { Text("\(title): (Cargando...)").font(.system(size: 16, weight: .thin)).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5) }
            else { DisclosureGroup(isExpanded: expanded) { filterCategoryGrid(title: title, options: options) } label: { Text(title).font(.system(size: 16, weight: .thin)).foregroundColor(Color("textoSecundario")).frame(maxWidth: .infinity, alignment: .leading) }.accentColor(Color("textoSecundario")) }
        }
    }
    private func filterPerfumePopularitySliderAccordion() -> some View {
        DisclosureGroup(isExpanded: $perfumePopularityExpanded) { perfumePopularitySlider() } label: { Text("Popularidad Perfume").font(.system(size: 16, weight: .thin)).foregroundColor(Color("textoSecundario")).frame(maxWidth: .infinity, alignment: .leading) }.accentColor(Color("textoSecundario"))
    }
    private func perfumePopularitySlider() -> some View {
        VStack(alignment: .leading) {
             ItsukiSlider(value: $perfumePopularityRange, in: perfumePopularitySliderRange, step: 1).frame(height: 12).padding(.top, 10).padding(.horizontal, 15)
             HStack { Spacer(); Text("Popularidad: \(Int(perfumePopularityRange.lowerBound)) - \(Int(perfumePopularityRange.upperBound))").font(.system(size: 14, weight: .light)); Spacer() }.padding(.top, 5)
        }.padding(.top, 8)
    }
    private func filterCategoryGrid(title: String, options: [FilterKeyPair]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(options) { optionPair in FilterButton(category: title, optionKey: optionPair.key, displayText: optionPair.name, isSelected: isSelected(category: title, option: optionPair.key)) { cat, optKey in toggleFilter(category: cat, option: optKey) } }
        }.padding(.top, 8)
    }
    struct FilterButton: View {
        let category: String; let optionKey: String; let displayText: String; let isSelected: Bool; let action: (String, String) -> Void
        var body: some View { Button(action: { action(category, optionKey) }) { Text(displayText).font(.system(size: 14)).frame(minWidth: 90, minHeight: 30).foregroundColor(isSelected ? .white : Color("textoPrincipal")).padding(.horizontal, 8).background(isSelected ? Color("champan") : Color("grisSuave")).cornerRadius(12) } }
    }
}

struct TopWishlistShareView: View {
    let items: [WishlistItemDisplayData]
    let selectedFilters: [String: [String]]
    let perfumePopularityRange: ClosedRange<Double>
    let searchText: String
    private let defaultPerfumePopularityRange: ClosedRange<Double> = 0...10
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    private var subtitleText: String? {
        var descriptions: [String] = []
        if !searchText.isEmpty { descriptions.append("Buscando \"\(searchText)\"") }
        if let genders = selectedFilters["Género"], !genders.isEmpty { descriptions.append("Género: \(genders.compactMap { Gender(rawValue: $0)?.displayName ?? $0 }.joined(separator: "/"))") }
        if let familiesKeys = selectedFilters["Familia Olfativa"], !familiesKeys.isEmpty { descriptions.append("Familia(s): \(familiesKeys.compactMap { key in familyViewModel.familias.first { $0.key == key }?.name ?? key }.joined(separator: "/"))") }
        if let seasons = selectedFilters["Temporada Recomendada"], !seasons.isEmpty { descriptions.append("Temporada: \(seasons.compactMap { Season(rawValue: $0)?.displayName ?? $0 }.joined(separator: "/"))") }
        if perfumePopularityRange != defaultPerfumePopularityRange { descriptions.append("Popularidad: \(Int(perfumePopularityRange.lowerBound))-\(Int(perfumePopularityRange.upperBound))") }
        return descriptions.isEmpty ? nil : descriptions.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mi Lista de Deseos")
                .font(.system(size: 24, weight: .bold)).padding(.bottom, 8)
            if let subtitle = subtitleText {
                Text(subtitle).font(.system(size: 14)).foregroundColor(.secondary).lineLimit(2).padding(.bottom, 8)
            }
            ForEach(items) { itemData in
                HStack(spacing: 12) {
                    KFImage(URL(string: itemData.perfume.imageURL ?? ""))
                         .placeholder { Image(systemName: "photo").resizable().scaledToFit().frame(width: 50, height: 50).foregroundColor(.gray).background(Color.gray.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8)) }
                         .resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 10)).clipped()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(itemData.perfume.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                        Text(brandViewModel.getBrand(byKey: itemData.perfume.brand)?.name ?? itemData.perfume.brand).font(.system(size: 14)).foregroundColor(.secondary).lineLimit(1)
                        if itemData.wishlistItem.rating > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                                Text("\(itemData.wishlistItem.rating, specifier: "%.1f")").font(.system(size: 13, weight: .medium)).foregroundColor(.gray)
                            }.padding(.top, 1)
                        }
                    }
                    Spacer()
                }
                 if itemData.id != items.last?.id { Divider().padding(.leading, 72) }
            }
            Spacer()
            Text("Compartido desde [Nombre de tu App]").font(.caption2).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center).padding(.top, 10)
        }.padding(20).background(Color(UIColor.systemBackground))
    }
}

// --- DEFINICIONES ADICIONALES REQUERIDAS ---
// Asegúrate que existan:
// Structs: Perfume, Brand, WishlistItem(id: String), PerfumeRowDisplayData, FilterKeyPair
// Enums: GradientPreset, Gender, Season, Projection, Duration, Price
// ViewModels: UserViewModel, BrandViewModel, PerfumeViewModel, FamilyViewModel
// Servicios/Helpers: ShareService, FilterInformationProvider
// Vistas: GradientView, ItsukiSlider, GenericPerfumeRowView, PerfumeDetailView
