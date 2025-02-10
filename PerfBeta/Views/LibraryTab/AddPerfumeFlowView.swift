import SwiftUI

struct AddPerfumeFlowView: View {
    @Environment(\.presentationMode) var presentationMode // Para cerrar la vista
    @Binding var selectedPerfume: Perfume?
    @EnvironmentObject var triedPerfumesManager: TriedPerfumesManager // Manager global de perfumes probados
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel // ViewModel de perfumes

    @State private var searchText: String = "" // Texto de búsqueda
    @State private var userImpressions: String = "" // Impresiones del usuario
    @State private var showImpressionsView: Bool = false // Control para la vista de impresiones

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barra superior con botón "X"
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Cerrar la vista
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color("textoPrincipal"))
                    }
                    Spacer()
                    Text("Selecciona un Perfume")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))
                    Spacer()
                }
                .padding()
                .background(Color("fondoClaro"))

                // Campo de búsqueda
                TextField("Buscar perfume o marca", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Lista de perfumes filtrados
                List(filteredPerfumes) { perfume in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(perfume.name)
                                .font(.headline)
                                .foregroundColor(Color("textoPrincipal"))
                            Text(perfume.brand)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle()) // Hace clickeable toda el área
                    .onTapGesture {
                        selectedPerfume = perfume // Selecciona el perfume
                    }
                    .background(selectedPerfume == perfume ? Color("champan").opacity(0.2) : Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color("fondoClaro"))
                .scrollContentBackground(.hidden)

                // Botón "Continuar" al final
                Button(action: {
                    showImpressionsView = true // Navegar a la vista de impresiones
                }) {
                    HStack {
                        Spacer()
                        Text("Continuar")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color("champan"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .disabled(selectedPerfume == nil) // Deshabilitar si no hay perfume seleccionado
                .opacity(selectedPerfume == nil ? 0.5 : 1.0) // Reducir opacidad si está deshabilitado
            }
            .background(Color("fondoClaro").edgesIgnoringSafeArea(.all)) // Fondo consistente con toda la vista
            .navigationBarHidden(true) // Ocultar barra de navegación
            .fullScreenCover(isPresented: $showImpressionsView) {
                if let perfume = selectedPerfume {
                    ImpressionsView(
                        selectedPerfume: perfume,
                        userImpressions: $userImpressions
                    ) {
                        // Acción al guardar
                        triedPerfumesManager.addPerfume(perfume) // Añade el perfume al manager
                        presentationMode.wrappedValue.dismiss() // Cierra el flujo
                        print("Perfume \(perfume.name) añadido con impresiones: \(userImpressions)")
                    }
                }
            }
        }
    }

    // Filtra perfumes por nombre o fabricante
    var filteredPerfumes: [Perfume] {
        if searchText.isEmpty {
            return perfumeViewModel.perfumes
        } else {
            return perfumeViewModel.perfumes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
