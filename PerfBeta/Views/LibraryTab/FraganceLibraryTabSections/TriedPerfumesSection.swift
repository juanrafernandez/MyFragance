import SwiftUI
import Kingfisher

struct TriedPerfumesSection<Destination: View>: View {
    let title: String
    @Binding var triedPerfumes: [TriedPerfumeRecord] // Sigue siendo un array de Records
    let maxDisplayCount: Int
    let addAction: () -> Void
    let seeMoreDestination: Destination
    @ObservedObject var userViewModel: UserViewModel // Recibe UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !triedPerfumes.isEmpty {
                    NavigationLink(destination: seeMoreDestination) {
                        Text("Ver más")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("textoPrincipal"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("champan").opacity(0.1))
                            )
                    }
                }
            }
            .padding(.bottom, 5)

            if triedPerfumes.isEmpty {
                // Empty State con diseño mejorado
                EmptyStateView(
                    type: .noTriedPerfumes,
                    action: addAction
                )
                .frame(minHeight: 300)
                .padding(.vertical, 20)

            } else {
                // --- Mostrar lista de perfumes ---
                VStack(alignment: .leading, spacing: 1) {
                    // --- CAMBIO 2: Modificar ForEach ---
                    ForEach(triedPerfumes.prefix(maxDisplayCount)) { record in // Iterar sobre los Records
                        // Buscar el Perfume correspondiente en el ViewModel
                        if let perfume = perfumeViewModel.perfumes.first(where: { $0.key == record.perfumeKey }),
                           let recordId = record.id { // Asegurarse de que el record tiene ID
                            // Crear el DisplayItem
                            let displayItem = TriedPerfumeDisplayItem(id: recordId, record: record, perfume: perfume)
                            // Pasar el DisplayItem a la vista de fila
                            TriedPerfumeRowView(displayItem: displayItem)
                        } else {
                            // Opcional: Mostrar algo si el perfume no se encuentra o el ID falta
                            // Text("Datos no encontrados para \(record.perfumeKey)")
                            //    .font(.caption).foregroundColor(.red).padding(.vertical, 5)
                            EmptyView() // O simplemente no mostrar la fila
                        }
                    }
                }
                // --- Botón "Añadir Perfume" (sin cambios) ---
                Button(action: addAction) {
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
                .padding(.top, 10)
            }
        }
        // Asegúrate de inyectar perfumeViewModel donde uses TriedPerfumesSection
        // .environmentObject(yourPerfumeViewModelInstance)
    }
}

// MARK: - TriedPerfumeRowView (MODIFICADA)
struct TriedPerfumeRowView: View {
    // --- CAMBIO 1: Recibir el DisplayItem ---
    let displayItem: TriedPerfumeDisplayItem

    // --- CAMBIO 2: Eliminar ViewModels innecesarios ---
    // Ya no necesitamos PerfumeViewModel ni UserViewModel aquí
    @EnvironmentObject var brandViewModel: BrandViewModel // Aún necesario para nombre de marca

    // --- CAMBIO 3: Eliminar Estado innecesario ---
    @State private var showingDetailView = false
    // Ya no necesitamos @State para detailedPerfume o detailedBrand

    // --- Dependencias para la vista detalle (inyectar si es necesario) ---
    // @EnvironmentObject var perfumeViewModel: PerfumeViewModel // Podría necesitarse en el detalle
    // @EnvironmentObject var userViewModel: UserViewModel // Podría necesitarse en el detalle
    // @EnvironmentObject var notesViewModel: NotesViewModel // Podría necesitarse en el detalle
    // @EnvironmentObject var familyViewModel: FamilyViewModel // Podría necesitarse en el detalle

    var body: some View {
        Button {
            showingDetailView = true
        } label: {
            HStack(spacing: 15) {
                // --- CAMBIO 4: Usar datos del DisplayItem ---
                KFImage(URL(string: displayItem.perfume.imageURL ?? ""))
                    .placeholder {
                        // Placeholder más genérico o uno específico si lo tienes
                        Image("placeholder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) { // Ajustar spacing si se desea
                    // Usar nombre del perfume directamente
                    Text(displayItem.perfume.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("textoPrincipal"))
                        .lineLimit(1) // Limitar a una línea

                    // Obtener nombre de marca usando ViewModel y la clave del perfume
                    Text(brandViewModel.getBrand(byKey: displayItem.perfume.brand)?.name ?? displayItem.perfume.brand) // Fallback a la clave si no se encuentra nombre
                        .font(.system(size: 12))
                        .foregroundColor(Color("textoSecundario"))
                        .lineLimit(1)
                }

                Spacer()

                // Mostrar Rating (usando el record del displayItem)
                if let rating = displayItem.record.rating {
                    HStack(spacing: 3) { // Ajustar spacing
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12, weight: .medium)) // Peso medio para destacar un poco
                            .foregroundColor(Color("textoSecundario")) // Usar color secundario
                    }
                } else {
                    // Opcional: Mostrar algo si no hay rating
                     Image(systemName: "star")
                         .foregroundColor(.gray.opacity(0.5))
                         .font(.system(size: 12))
                }
            }
            .padding(.vertical, 8) // Ajustar padding vertical
            .padding(.horizontal, 5) // Padding horizontal ligero
            .background(Color.clear) // Asegurar fondo transparente
            // --- CAMBIO 5: Eliminar .task ---
            // .task { await loadTriedPerfumeAndBrand() } // Ya no es necesario
        }
        .buttonStyle(.plain) // Evitar estilo por defecto del botón
        .fullScreenCover(isPresented: $showingDetailView) {
            // --- CAMBIO 6: Pasar datos del DisplayItem a la vista detalle ---
            // Asume que PerfumeLibraryDetailView acepta perfume y record
            PerfumeLibraryDetailView(
                perfume: displayItem.perfume,
                triedPerfume: displayItem.record // Pasar el record original
            )
            // Asegúrate de inyectar TODOS los EnvironmentObjects necesarios para PerfumeLibraryDetailView
            // .environmentObject(perfumeViewModel)
            // .environmentObject(brandViewModel)
            // .environmentObject(userViewModel)
            // .environmentObject(notesViewModel)
            // .environmentObject(familyViewModel)

        }
    }

    // --- CAMBIO 7: Eliminar función de carga ---
    // private func loadTriedPerfumeAndBrand() async { ... } // Ya no es necesaria
}
