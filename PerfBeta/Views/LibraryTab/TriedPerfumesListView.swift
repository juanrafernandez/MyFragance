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

    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan
    @State private var combinedDisplayItems: [TriedPerfumeDisplayItem] = []
    @State private var filteredAndSortedDisplayItems: [TriedPerfumeDisplayItem] = []
    @State private var selectedDisplayItem: TriedPerfumeDisplayItem? = nil

    let triedPerfumesInput: [TriedPerfumeRecord]
    private let shareService = FragranceLibraryShareService()

    init(triedPerfumesInput: [TriedPerfumeRecord], familyViewModel: FamilyViewModel) {
        self.triedPerfumesInput = triedPerfumesInput
        self._filterViewModel = StateObject(wrappedValue: FilterViewModel(
            configuration: .triedPerfumes(),
            familyViewModel: familyViewModel
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: selectedGradientPreset)
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
                    .padding(.horizontal, 25)
                }
            }
        }
        .padding(.bottom, 5)
        .navigationBarHidden(true)
        .onAppear(perform: mapInputAndFilter)
        .onChange(of: triedPerfumesInput) {
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
            Button { dismiss() } label: { Image(systemName: "chevron.backward").foregroundColor(Color("textoPrincipal")).font(.title2) }
                .padding(.trailing, 5)

            Text("Perfumes Probados".uppercased())
                .font(.system(size: 18, weight: .light)).foregroundColor(Color("textoPrincipal")).lineLimit(1)

            Spacer()

            Button { Task { await shareTriedPerfumes() } } label: { Image(systemName: "square.and.arrow.up").foregroundColor(Color("textoPrincipal")).font(.title2) }
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

    private var emptyOrNoResultsView: some View {
        VStack {
            Spacer()
            Text(filterViewModel.hasActiveFilters ? "No se encontraron perfumes con los filtros seleccionados." : "No has probado ningún perfume todavía.")
                .font(.title3)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
    }

    private var perfumeListView: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(filteredAndSortedDisplayItems) { item in
                let rowData = PerfumeRowDisplayData(
                    id: item.id,
                    perfumeKey: item.perfume.key,
                    brandKey: item.perfume.brand,
                    imageURL: item.perfume.imageURL,
                    initialPerfumeName: item.perfume.name,
                    initialBrandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name,
                    personalRating: item.personalRating,
                    generalRating: nil,
                    onTapAction: {
                        print("Tapped on (Tried): \(item.perfume.name)")
                        selectedDisplayItem = item
                    }
                )

                VStack(alignment: .leading, spacing: 0) {
                    GenericPerfumeRowView(data: rowData)
                }
            }
        }
    }

    private func mapInputAndFilter() {
        mapInputToDisplayItems()
        applyFilters()
    }

    private func mapInputToDisplayItems() {
        print("Mapeando \(triedPerfumesInput.count) records a display items...")
        let perfumeDict = Dictionary(uniqueKeysWithValues: perfumeViewModel.perfumes.map { ($0.key, $0) })
        print("Diccionario de perfumes creado con \(perfumeDict.count) entradas.")

        combinedDisplayItems = triedPerfumesInput.compactMap { record -> TriedPerfumeDisplayItem? in
            guard let recordId = record.id else {
                print("Saltando record sin ID: \(record.perfumeKey)")
                return nil
            }
            if let perfume = perfumeDict[record.perfumeKey] {
                return TriedPerfumeDisplayItem(id: recordId, record: record, perfume: perfume)
            } else {
                print("Perfume no encontrado en ViewModel para key: \(record.perfumeKey)")
                return nil
            }
        }
        print("Mapeo completado. \(combinedDisplayItems.count) display items creados.")
    }

    private func applyFilters() {
        print("Aplicando filtros desde la vista...")
        filteredAndSortedDisplayItems = filterViewModel.applyFiltersAndSort(
            items: combinedDisplayItems,
            brandViewModel: brandViewModel
        )
        print("Filtros aplicados. Mostrando \(filteredAndSortedDisplayItems.count) items.")
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

        print("Texto generado para compartir Probados (refactorizado): \(baseText)")
        return baseText
    }
}
