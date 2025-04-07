import SwiftUI

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
    private let itemsPerPage = 20

    var body: some View {
        VStack {
            TextField("Buscar perfume o marca", text: $searchText)
                .padding(7)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal)

            if perfumeViewModel.isLoading {
                ProgressView("Cargando perfumes...")
            } else if !perfumeViewModel.perfumes.isEmpty {
                ScrollView {
                    LazyVStack {
                        ForEach(filteredPerfumes(), id: \.id) { perfume in
                            NavigationLink(destination: AddPerfumeStep2View(selectedPerfume: perfume, isAddingPerfume: $isAddingPerfume, showingEvaluationOnboarding: $showingEvaluationOnboarding)) {
                                PerfumeCardRow(perfume: perfume, brandViewModel: brandViewModel)
                            }
                            Divider()
                        }
                        if !perfumeViewModel.isLoading {
                            ProgressView("Cargando más perfumes...")
                                .onAppear {
                                    print("Cargando más perfumes - Funcionalidad no implementada en este ejemplo")
                                }
                        }
                    }
                }
            } else if perfumeViewModel.errorMessage != nil {
                Text("Error al cargar los perfumes. Por favor, inténtalo de nuevo.")
                    .foregroundColor(.red)
            } else {
                Text("No se encontraron perfumes.")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            if let initialPerfume = initialSelectedPerfume {
                selectedPerfume = initialPerfume
            }
        }
    }

    private func filteredPerfumes() -> [Perfume] {
        if searchText.isEmpty {
            return perfumeViewModel.perfumes
        } else {
            return perfumeViewModel.perfumes.filter { perfume in
                perfume.name.localizedCaseInsensitiveContains(searchText) ||
                perfume.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
