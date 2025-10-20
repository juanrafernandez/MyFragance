import SwiftUI
import Sliders

struct PerfumeFilterView<Item: FilterablePerfumeItem>: View {
    @ObservedObject var viewModel: FilterViewModel<Item> // Usar ObservedObject aquí

    // Necesitamos acceso a las opciones generadas por el ViewModel
    // (o inyectar FamilyViewModel aquí también, pero es mejor que el ViewModel las provea)

    var body: some View {
        VStack(spacing: 0) { // Ajusta el spacing según necesites
            searchSection
            filterSection
            Divider().padding(.top, 5) // Opcional: separador visual
        }
    }

    private var searchSection: some View {
        TextField("Buscar perfume o marca...", text: $viewModel.searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.bottom, 8)
            // Añade padding horizontal si es necesario aquí o en el contenedor padre
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterCategoryAccordion(title: "Género",
                                    options: viewModel.genderOptions,
                                    expanded: $viewModel.genreExpanded)
            filterCategoryAccordion(title: "Familia Olfativa",
                                    options: viewModel.familyOptions,
                                    expanded: $viewModel.familyExpanded)
            filterCategoryAccordion(title: "Temporada Recomendada",
                                    options: viewModel.seasonOptions,
                                    expanded: $viewModel.seasonExpanded)
            filterCategoryAccordion(title: "Proyección",
                                    options: viewModel.projectionOptions,
                                    expanded: $viewModel.projectionExpanded)
            filterCategoryAccordion(title: "Duración",
                                    options: viewModel.durationOptions,
                                    expanded: $viewModel.durationExpanded)
            filterCategoryAccordion(title: "Precio",
                                    options: viewModel.priceOptions,
                                    expanded: $viewModel.priceExpanded)

            // Sliders Condicionales
            if viewModel.configuration.showPersonalRatingFilter {
                filterRatingSliderAccordion()
            }
            filterPerfumePopularitySliderAccordion()
        }
        .padding(.vertical, 8)
    }

    // --- Vistas de Acordeones y Grids (muy similares a las originales) ---

    private func filterCategoryAccordion(title: String, options: [FilterKeyPair], expanded: Binding<Bool>) -> some View {
         Group {
             if options.isEmpty {
                 // Opcional: Mostrar estado de carga si las opciones dependen de una carga asíncrona
                 Text("\(title): (Cargando...)")
                     .font(.system(size: 16, weight: .thin))
                     .foregroundColor(.gray)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .padding(.vertical, 5)
             } else {
                 DisclosureGroup(isExpanded: expanded) {
                     filterCategoryGrid(title: title, options: options)
                 } label: {
                     Text(title)
                         .font(.system(size: 16, weight: .thin))
                         .foregroundColor(Color("textoSecundario")) // Usa tus colores
                         .frame(maxWidth: .infinity, alignment: .leading)
                 }
                 .accentColor(Color("textoSecundario")) // Usa tus colores
             }
         }
     }

    private func filterCategoryGrid(title: String, options: [FilterKeyPair]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(options) { optionPair in
                FilterButton(
                    category: title,
                    optionKey: optionPair.key,
                    displayText: optionPair.name,
                    // Corregir la etiqueta del segundo argumento aquí:
                    isSelected: viewModel.isSelected(category: title, optionKey: optionPair.key) 
                ) { cat, optKey in
                    viewModel.toggleFilter(category: cat, optionKey: optKey)
                }
            }
        }
        .padding(.top, 8)
    }

    // Acordeón y Slider para Rating Personal
    private func filterRatingSliderAccordion() -> some View {
        DisclosureGroup(isExpanded: $viewModel.personalRatingExpanded) {
            ratingSlider()
        } label: {
            Text("Rating Personal")
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(Color("textoSecundario"))
    }

    private func ratingSlider() -> some View {
        VStack(alignment: .leading) {
             ItsukiSlider(value: $viewModel.ratingRange, in: viewModel.ratingSliderRange, step: 1)
                .frame(height: 12)
                .padding(.top, 10).padding(.horizontal, 15)

            HStack {
                Spacer()
                Text("Rating: \(Int(viewModel.ratingRange.lowerBound)) - \(Int(viewModel.ratingRange.upperBound))")
                    .font(.system(size: 14, weight: .light))
                Spacer()
            }.padding(.top, 5)
        }.padding(.top, 8)
    }

    // Acordeón y Slider para Popularidad Perfume
     private func filterPerfumePopularitySliderAccordion() -> some View {
        DisclosureGroup(isExpanded: $viewModel.perfumePopularityExpanded) {
            perfumePopularitySlider()
        } label: {
            Text("Popularidad Perfume")
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(Color("textoSecundario"))
    }

     private func perfumePopularitySlider() -> some View {
        VStack(alignment: .leading) {
             ItsukiSlider(value: $viewModel.perfumePopularityRange, in: viewModel.perfumePopularitySliderRange, step: 1)
                .frame(height: 12)
                .padding(.top, 10).padding(.horizontal, 15)

            HStack {
                Spacer()
                Text("Popularidad: \(Int(viewModel.perfumePopularityRange.lowerBound)) - \(Int(viewModel.perfumePopularityRange.upperBound))")
                    .font(.system(size: 14, weight: .light))
                Spacer()
            }.padding(.top, 5)
        }.padding(.top, 8)
    }

    // --- Botón de Filtro (igual que antes, pero usa optionKey) ---
    struct FilterButton: View {
        let category: String
        let optionKey: String // Clave para la lógica
        let displayText: String // Texto para mostrar
        let isSelected: Bool
        let action: (String, String) -> Void // Acción usa la clave

        var body: some View {
            Button(action: { action(category, optionKey) }) {
                Text(displayText)
                    .font(.system(size: 14))
                    .frame(minWidth: 90, minHeight: 30) // Ajusta según diseño
                    .foregroundColor(isSelected ? .white : Color("textoPrincipal"))
                    .padding(.horizontal, 8)
                    .background(isSelected ? Color("champan") : Color("grisSuave")) // Usa tus colores
                    .cornerRadius(12)
            }
        }
    }
}
