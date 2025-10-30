import SwiftUI
import Kingfisher

struct TriedPerfumesSection: View {
    let title: String
    let triedPerfumes: [TriedPerfume] // ✅ No necesita Binding - solo lectura
    let maxDisplayCount: Int
    let addAction: () -> Void
    @ObservedObject var userViewModel: UserViewModel // Recibe UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !triedPerfumes.isEmpty {
                    // ✅ CRITICAL FIX: Lazy loading - la vista se crea SOLO al navegar
                    NavigationLink {
                        TriedPerfumesListView(
                            triedPerfumesInput: triedPerfumes,
                            familyViewModel: familyViewModel
                        )
                    } label: {
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

            // ✅ SIMPLIFICADO: Usar solo isLoadingTriedPerfumes
            if userViewModel.isLoadingTriedPerfumes {
                LoadingView(message: "Cargando perfumes...", style: .inline)
                    .frame(height: 100)
            }
            else if triedPerfumes.isEmpty {
                EmptyStateView(
                    type: .noTriedPerfumes,
                    action: addAction,
                    compact: true
                )
                .frame(height: 150)
            } else {
                // --- Mostrar lista de perfumes ---
                VStack(alignment: .leading, spacing: 1) {
                    // ✅ CRITICAL FIX: Usar búsqueda O(1) en lugar de O(n)
                    ForEach(triedPerfumes.prefix(maxDisplayCount)) { record in
                        // ✅ Búsqueda instantánea O(1) usando índice de diccionario
                        if let perfume = perfumeViewModel.getPerfumeFromIndex(byKey: record.perfumeId),
                           let recordId = record.id {
                            let displayItem = TriedPerfumeDisplayItem(id: recordId, record: record, perfume: perfume)
                            TriedPerfumeRowView(displayItem: displayItem)
                        } else {
                            // ⚠️ DEBUG: Perfume no encontrado en el índice
                            Text("Perfume no encontrado")
                                .font(.caption)
                                .foregroundColor(.red)
                                .onAppear {
                                    print("⚠️ [TriedPerfumesSection] Perfume con key '\(record.perfumeId)' no encontrado en índice")
                                    print("   - Índice tiene \(perfumeViewModel.perfumeIndex.count) perfumes")
                                    print("   - Array tiene \(perfumeViewModel.perfumes.count) perfumes")
                                }
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
                // ✅ Fix: Use flatMap to safely create URL only if imageURL is valid
                KFImage(displayItem.perfume.imageURL.flatMap { URL(string: $0) })
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .cacheMemoryOnly(false)
                    .diskCacheExpiration(.never)
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
                // ✅ REFACTOR: rating ya no es opcional en TriedPerfume
                HStack(spacing: 3) { // Ajustar spacing
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                    Text(String(format: "%.1f", displayItem.record.rating))
                        .font(.system(size: 12, weight: .medium)) // Peso medio para destacar un poco
                        .foregroundColor(Color("textoSecundario")) // Usar color secundario
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
