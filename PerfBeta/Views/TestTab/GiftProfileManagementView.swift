import SwiftUI

struct GiftProfileManagementView: View {
    // MARK: - Environment Objects & State
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showingDeleteAlert = false
    @State private var profileToDelete: UnifiedProfile? = nil
    @State private var selectedProfile: UnifiedProfile? = nil

    // MARK: - Body
    var body: some View {
        ZStack {
            // ✅ Fondo gradient de la app
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // ✅ Texto explicativo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gestiona tus perfiles de regalo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.textPrimary)

                    Text("Toca un perfil para verlo. Mantén pulsado para cambiar el orden. Desliza hacia la izquierda para eliminar.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.spacing16)
                .padding(.bottom, 12)

                List {
                    // Itera sobre los perfiles directamente desde el ViewModel
                    ForEach(giftRecommendationViewModel.savedProfiles) { profile in
                        giftProfileRow(for: profile)
                    }
                    // Habilitar movimiento solo en modo edición
                    .onMove(perform: moveProfiles)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden) // ✅ Ocultar fondo blanco del List
                .background(Color.clear) // ✅ Fondo transparente para mostrar gradient
            }
        }
        .navigationTitle("Perfiles de Regalo")
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
    // Función auxiliar para crear la fila de perfil
    @ViewBuilder
    private func giftProfileRow(for profile: UnifiedProfile) -> some View {
        // Extraer familias del perfil unificado
        let families: [String] = [profile.primaryFamily] + profile.subfamilies

        ProfileCardView(
            title: profile.displayName,
            description: profile.summary,
            familyColors: Array(families.prefix(3))
        )
        .environmentObject(familyViewModel)
            .listRowInsets(EdgeInsets(top: 8, leading: 25, bottom: 8, trailing: 25))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedProfile = profile
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    profileToDelete = profile
                    showingDeleteAlert = true
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
    }

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
