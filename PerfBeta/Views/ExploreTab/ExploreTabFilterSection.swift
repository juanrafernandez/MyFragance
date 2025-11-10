import SwiftUI
import Sliders

/// Sección de filtros para ExploreTab
/// Contiene todos los acordeones de filtros (Género, Familia, Temporada, etc.)
struct ExploreTabFilterSection: View {
    // MARK: - Bindings
    @Binding var selectedFilters: [String: [String]]
    @Binding var genreExpanded: Bool
    @Binding var familyExpanded: Bool
    @Binding var seasonExpanded: Bool
    @Binding var projectionExpanded: Bool
    @Binding var durationExpanded: Bool
    @Binding var priceExpanded: Bool
    @Binding var popularityExpanded: Bool
    @Binding var popularityRange: ClosedRange<Double>

    // MARK: - Environment Objects
    @EnvironmentObject var familyViewModel: FamilyViewModel

    // MARK: - Properties
    let range: ClosedRange<Double> = 0...10
    let onFilterChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Género
            filterCategoryAccordion(
                title: "Género",
                options: Gender.allCases.map { $0.displayName },
                expanded: $genreExpanded
            )

            // Familia Olfativa
            filterCategoryAccordion(
                title: "Familia Olfativa",
                options: familyViewModel.familias.map { $0.name },
                expanded: $familyExpanded
            )

            // Temporada
            filterCategoryAccordion(
                title: "Temporada Recomendada",
                options: Season.allCases.map { $0.displayName },
                expanded: $seasonExpanded
            )

            // Proyección
            filterCategoryAccordion(
                title: "Proyección",
                options: Projection.allCases.map { $0.displayName },
                expanded: $projectionExpanded
            )

            // Duración
            filterCategoryAccordion(
                title: "Duración",
                options: Duration.allCases.map { $0.displayName },
                expanded: $durationExpanded
            )

            // Precio
            filterCategoryAccordion(
                title: "Precio",
                options: Price.allCases.map { $0.displayName },
                expanded: $priceExpanded
            )

            // Popularidad (slider)
            filterPopularitySliderAccordion()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Filter Accordion
    private func filterCategoryAccordion(title: String, options: [String], expanded: Binding<Bool>) -> some View {
        DisclosureGroup(
            isExpanded: expanded,
            content: {
                filterCategoryGrid(title: title, options: options)
            },
            label: {
                Text(title)
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(Color("textoSecundario"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .accentColor(Color("textoSecundario"))
    }

    // MARK: - Popularity Slider Accordion
    private func filterPopularitySliderAccordion() -> some View {
        DisclosureGroup(
            isExpanded: $popularityExpanded,
            content: {
                popularitySlider()
            },
            label: {
                Text("Popularidad")
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(Color("textoSecundario"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .accentColor(Color("textoSecundario"))
    }

    // MARK: - Popularity Slider
    private func popularitySlider() -> some View {
        VStack(alignment: .leading) {
            ItsukiSlider(value: $popularityRange, in: range, step: 1)
                .frame(height: 12)
                .onChange(of: popularityRange) {
                    // Ajustar bounds si son iguales
                    if popularityRange.lowerBound == range.upperBound {
                        let adjustedLowerBound = popularityRange.lowerBound - 1
                        popularityRange = (adjustedLowerBound >= 0 ? adjustedLowerBound : 0)...popularityRange.upperBound
                    } else if popularityRange.upperBound == range.lowerBound {
                        let adjustedUpperBound = popularityRange.upperBound + 1
                        popularityRange = popularityRange.lowerBound...(adjustedUpperBound > 10 ? 10 : adjustedUpperBound)
                    }
                    onFilterChange()
                }
                .padding(.top, 10)
                .padding(.horizontal, 15)

            HStack {
                Spacer()
                Text("Popularidad Seleccionada: \(Int(popularityRange.lowerBound)) - \(Int(popularityRange.upperBound))")
                    .font(.system(size: 14, weight: .light))
                Spacer()
            }
            .padding(.top, 5)
        }
        .padding(.top, 8)
    }

    // MARK: - Filter Grid
    private func filterCategoryGrid(title: String, options: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(options, id: \.self) { option in
                FilterButton(
                    category: title,
                    option: option,
                    isSelected: isSelected(category: title, option: option)
                ) { cat, opt in
                    toggleFilter(category: cat, option: opt)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Filter Logic
    private func toggleFilter(category: String, option: String) {
        if selectedFilters[category]?.contains(option) == true {
            selectedFilters[category]?.removeAll(where: { $0 == option })
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            if selectedFilters[category] == nil {
                selectedFilters[category] = []
            }
            selectedFilters[category]?.append(option)
        }
        onFilterChange()
    }

    private func isSelected(category: String, option: String) -> Bool {
        return selectedFilters[category]?.contains(option) == true
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let category: String
    let option: String
    let isSelected: Bool
    let action: (String, String) -> Void

    var body: some View {
        Button(action: {
            action(category, option)
        }) {
            Text(option)
                .font(.system(size: 14))
                .frame(minWidth: 90, minHeight: 30)
                .foregroundColor(isSelected ? .white : Color("textoPrincipal"))
                .padding(.horizontal, 8)
                .background(isSelected ? Color("champan") : Color("grisSuave"))
                .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        ExploreTabFilterSection(
            selectedFilters: .constant(["Género": ["Masculino"], "Familia Olfativa": ["Amaderados"]]),
            genreExpanded: .constant(true),
            familyExpanded: .constant(false),
            seasonExpanded: .constant(false),
            projectionExpanded: .constant(false),
            durationExpanded: .constant(false),
            priceExpanded: .constant(false),
            popularityExpanded: .constant(false),
            popularityRange: .constant(0...10),
            onFilterChange: {}
        )
        .environmentObject(FamilyViewModel(familiaService: DependencyContainer.shared.familyService))
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
