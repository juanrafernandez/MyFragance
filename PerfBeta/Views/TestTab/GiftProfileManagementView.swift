import SwiftUI

struct GiftProfileManagementView: View {
    // MARK: - Environment Objects & State
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showingDeleteAlert = false
    @State private var profileToDelete: GiftProfile? = nil
    @State private var selectedProfile: GiftProfile? = nil

    // MARK: - Body
    var body: some View {
        List {
            // Itera sobre los perfiles directamente desde el ViewModel
            ForEach(giftRecommendationViewModel.savedProfiles) { profile in
                ProfileCardView(
                    title: profile.displayName,
                    description: profile.summary,
                    gradientColors: [Color("champan").opacity(0.1), .white]
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle()) // Asegura que toda la fila sea tappable
                .onTapGesture {
                    // Permite seleccionar para ver detalle
                    selectedProfile = profile
                }
                // Acciones de swipe para eliminar
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        profileToDelete = profile
                        showingDeleteAlert = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
            // Habilitar siempre el movimiento
            .onMove(perform: moveProfiles)
        }
        .listStyle(PlainListStyle())
        // Habilita el modo edición para permitir .onMove
        .environment(\.editMode, .constant(.active)) // Mantenido activo para permitir .onMove
        .navigationTitle("Gestión de Perfiles de Regalo") // Título de la barra
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Oculta el botón de atrás por defecto
        .toolbar {
            // Botón de Atrás Personalizado
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor) // Usa el color de acento
                }
            }
        }
        // Alerta de Confirmación de Borrado
        .alert("Confirmar Eliminación", isPresented: $showingDeleteAlert, presenting: profileToDelete) { profile in
            // Botones de la alerta
            Button("Eliminar", role: .destructive) {
                Task {
                    // Llama al ViewModel para borrar (profile ya no es opcional aquí)
                    await giftRecommendationViewModel.deleteProfile(profile)
                    profileToDelete = nil // Limpia estado después de acción
                }
            }
            Button("Cancelar", role: .cancel) {
                profileToDelete = nil // Limpia estado si cancela
            }
        } message: { profile in
            // Mensaje de la alerta
            Text("¿Estás seguro de que deseas eliminar el perfil '\(profile.displayName)'?")
        }
        // Presentación Modal de la Vista de Resultados de Regalo
        .fullScreenCover(item: $selectedProfile) { profile in
            GiftResultsView(
                onDismiss: {
                    selectedProfile = nil
                },
                isStandalone: true  // ✅ Mostrar con fondo y botón X
            )
            .environmentObject(giftRecommendationViewModel)
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
            .onAppear {
                // Cargar el perfil seleccionado
                giftRecommendationViewModel.loadProfile(profile)
            }
        }
    }

    // MARK: - Private Methods
    // Función para manejar el movimiento y guardar el nuevo orden
    private func moveProfiles(from source: IndexSet, to destination: Int) {
        var orderedProfiles = giftRecommendationViewModel.savedProfiles
        orderedProfiles.move(fromOffsets: source, toOffset: destination)
        // Asume que updateOrder es async ahora en el ViewModel
        Task {
            await giftRecommendationViewModel.updateOrder(newOrderedProfiles: orderedProfiles)
        }
    }
}
