import SwiftUI

struct ProfileManagementView: View {
    // MARK: - Environment Objects & State
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel // Necesario para ProfileCardView
    @Environment(\.presentationMode) var presentationMode

    @State private var showingDeleteAlert = false
    @State private var profileToDelete: OlfactiveProfile? = nil
    @State private var selectedProfile: OlfactiveProfile? = nil

    // MARK: - Body
    var body: some View {
        List {
            // Itera sobre los perfiles directamente desde el ViewModel
            ForEach(olfactiveProfileViewModel.profiles) { profile in
                ProfileCardView(
                    title: profile.name,
                    description: familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyDescription ?? "",
                    gradientColors: [Color(hex: familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyColor ?? "#FFFFFF").opacity(0.1), .white]
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) { // allowsFullSwipe: false es opcional
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
            // .onDelete(perform: deleteProfiles) // Comentado: Usar swipeActions en su lugar
        }
        .listStyle(PlainListStyle())
        // Habilita el modo edición para permitir .onMove
        // NOTA: Sin un botón explícito, el usuario no verá los controles de reordenación estándar,
        // pero el gesto de mantener presionado y arrastrar SÍ funcionará.
        .environment(\.editMode, .constant(.active)) // Mantenido activo para permitir .onMove
        .navigationTitle("Gestión de Perfiles") // Título de la barra
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
                    await olfactiveProfileViewModel.deleteProfile(profile: profile)
                    profileToDelete = nil // Limpia estado después de acción
                }
            }
            Button("Cancelar", role: .cancel) {
                profileToDelete = nil // Limpia estado si cancela
            }
        } message: { profile in
            // Mensaje de la alerta
            Text("¿Estás seguro de que deseas eliminar el perfil '\(profile.name)'?")
        }
        // Presentación Modal de la Vista de Detalle
        .fullScreenCover(item: $selectedProfile) { profile in
            TestResultFullScreenView(profile: profile)
                .environmentObject(olfactiveProfileViewModel) // Inyectar dependencias
                .environmentObject(familyViewModel)
        }
        // Considera añadir .task y .onDisappear si esta vista gestiona el ciclo de vida del listener
    }

    // MARK: - Private Methods
    // Función para manejar el movimiento y guardar el nuevo orden
    private func moveProfiles(from source: IndexSet, to destination: Int) {
        var orderedProfiles = olfactiveProfileViewModel.profiles
        orderedProfiles.move(fromOffsets: source, toOffset: destination)
        // Asume que updateOrder es async ahora en el ViewModel
        Task {
            await olfactiveProfileViewModel.updateOrder(newOrderedProfiles: orderedProfiles)
        }
    }

    // Función para eliminar (llamada por .onDelete si se habilita, no por swipeActions)
    // Mantenida por si se reactiva .onDelete, pero no se usa con swipeActions
    private func deleteProfiles(at offsets: IndexSet) {
        let profilesToDelete = offsets.map { olfactiveProfileViewModel.profiles[$0] }
        if let firstProfile = profilesToDelete.first {
            profileToDelete = firstProfile
            showingDeleteAlert = true
        }
    }
}
