import SwiftUI

struct ProfileManagementView: View {
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    @State private var profileToDelete: OlfactiveProfile? = nil
    @State private var selectedProfile: OlfactiveProfile? = nil
    @State private var isEditing = false

    var body: some View {
        List {
            ForEach(olfactiveProfileViewModel.profiles) { profile in
                ProfileCardView(
                    title: profile.name,
                    description: familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyDescription ?? "",
                    gradientColors: [Color(hex: familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")?.familyColor ?? "#FFFFFF").opacity(0.1), .white]
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !isEditing else { return }
                    selectedProfile = profile
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        profileToDelete = profile
                        showingDeleteAlert = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: moveProfiles)
            .onDelete(perform: deleteProfiles)
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .navigationBarTitle("Gestión de Perfiles", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if !olfactiveProfileViewModel.profiles.isEmpty {
                        Button(isEditing ? "Listo" : "Reordenar") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                    }
                    
                    Button("Hecho") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Confirmar Eliminación"),
                message: Text("¿Estás seguro de que deseas eliminar el perfil '\(profileToDelete?.name ?? "")'?"),
                primaryButton: .destructive(Text("Eliminar")) {
                    Task {
                        if let profile = profileToDelete {
                            await olfactiveProfileViewModel.deleteProfile(profile)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .fullScreenCover(item: $selectedProfile) { profile in
            TestResultFullScreenView(profile: profile)
        }
    }
    
    private func moveProfiles(from source: IndexSet, to destination: Int) {
        olfactiveProfileViewModel.profiles.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteProfiles(at offsets: IndexSet) {
        offsets.forEach { index in
            profileToDelete = olfactiveProfileViewModel.profiles[index]
            showingDeleteAlert = true
        }
    }
}
