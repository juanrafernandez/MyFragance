import SwiftUI

struct TriedPerfumesListView: View {
    @EnvironmentObject var triedPerfumesManager: TriedPerfumesManager // Acceso al manager global
    @State private var isAddingPerfume = false // Controla si se muestra AddPerfumeFlowView
    @State private var selectedPerfume: Perfume? = nil // Perfume seleccionado durante el proceso

    var body: some View {
        VStack(spacing: 0) {
            // Tabla de perfumes probados
            List {
                ForEach(triedPerfumesManager.triedPerfumes) { perfume in
                    HStack {
                        // Imagen y detalles del perfume
                        Image(perfume.image_name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        VStack(alignment: .leading) {
                            Text(perfume.nombre)
                                .font(.headline)
                            Text(perfume.fabricante)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onMove(perform: moveItem) // Permite reordenar elementos
                .onDelete(perform: deleteItems) // Elimina directamente sin confirmación
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color("fondoClaro")) // Fondo consistente con la interfaz
            .scrollContentBackground(.hidden) // Elimina el fondo predeterminado de la List
            .toolbar {
                EditButton() // Botón para habilitar el modo de edición
            }

            // Fondo del botón ajustado al color de la interfaz
            VStack {
                Button(action: {
                    isAddingPerfume = true // Mostrar AddPerfumeFlowView
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Añadir Perfume")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("champan"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 16) // Margen adicional para separarlo de la TabView
            }
            .background(Color("fondoClaro")) // Fondo consistente con la interfaz
        }
        .background(Color("fondoClaro")) // Fondo general
        .navigationTitle("Tus Perfumes Probados")
        .fullScreenCover(isPresented: $isAddingPerfume) {
            AddPerfumeFlowView(selectedPerfume: $selectedPerfume)
        }
    }

    // MARK: - Función para reordenar perfumes
    private func moveItem(from source: IndexSet, to destination: Int) {
        triedPerfumesManager.triedPerfumes.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Eliminar perfume
    private func deleteItems(at offsets: IndexSet) {
        triedPerfumesManager.triedPerfumes.remove(atOffsets: offsets)
    }
}
