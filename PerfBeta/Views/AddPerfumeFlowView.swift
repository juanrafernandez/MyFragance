import SwiftUI

struct AddPerfumeFlowView: View {
    @Environment(\.presentationMode) var presentationMode // Para cerrar la vista
    @Binding var selectedPerfume: Perfume?
    @EnvironmentObject var triedPerfumesManager: TriedPerfumesManager // Manager global de perfumes probados

    @State private var searchText: String = "" // Texto de búsqueda
    @State private var userImpressions: String = "" // Impresiones del usuario
    @State private var showImpressionsView: Bool = false // Control para la vista de impresiones

    let perfumes: [Perfume] = PerfumeManager().getAllPerfumes() // Todos los perfumes disponibles

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
                            Text(perfume.nombre)
                                .font(.headline)
                                .foregroundColor(Color("textoPrincipal"))
                            Text(perfume.marca)
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
                        print("Perfume \(perfume.nombre) añadido con impresiones: \(userImpressions)")
                    }
                }
            }
        }
    }

    // Filtra perfumes por nombre o fabricante
    var filteredPerfumes: [Perfume] {
        if searchText.isEmpty {
            return perfumes
        } else {
            return perfumes.filter {
                $0.nombre.localizedCaseInsensitiveContains(searchText) ||
                $0.marca.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct ImpressionsView: View {
    let selectedPerfume: Perfume
    @Binding var userImpressions: String
    let onSave: () -> Void

    var body: some View {
        VStack {
            // Información del perfume seleccionado
            HStack {
                Image(selectedPerfume.imagenURL)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                VStack(alignment: .leading) {
                    Text(selectedPerfume.nombre)
                        .font(.headline)
                    Text(selectedPerfume.marca)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding()

            // Cuadro para escribir impresiones
            TextField("Escribe tus impresiones aquí...", text: $userImpressions)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Botón Guardar
            Button(action: onSave) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Guardar")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("champan"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .background(Color("fondoClaro").edgesIgnoringSafeArea(.all))
        .navigationTitle("Añadir Impresiones")
        .navigationBarTitleDisplayMode(.inline)
    }
}
