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
        ZStack {
            // ✅ Fondo gradient de la app
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // ✅ Texto explicativo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gestiona tus perfiles olfativos")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("textoPrincipal"))

                    Text("Toca un perfil para verlo. Mantén pulsado para cambiar el orden. Desliza hacia la izquierda para eliminar.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 25)
                .padding(.top, 16)
                .padding(.bottom, 12)

                List {
                    // Itera sobre los perfiles directamente desde el ViewModel
                    ForEach(olfactiveProfileViewModel.profiles) { profile in
                        ProfileCardView(
                            title: profile.name,
                            description: familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyDescription ?? "",
                            gradientColors: [Color(hex: familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyColor ?? "#FFFFFF").opacity(0.1), .white]
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 25, bottom: 8, trailing: 25))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle()) // Asegura que toda la fila sea tappable
                        .onTapGesture {
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
                    // Habilitar movimiento solo en modo edición
                    .onMove(perform: moveProfiles)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden) // ✅ Ocultar fondo blanco del List
                .background(Color.clear) // ✅ Fondo transparente para mostrar gradient
            }
        }
        .navigationTitle("Perfiles Olfativos")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Botón de Atrás Personalizado
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
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
