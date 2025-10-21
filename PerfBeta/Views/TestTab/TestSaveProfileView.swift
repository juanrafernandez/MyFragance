import SwiftUI

struct SaveProfileView: View {
    let profile: OlfactiveProfile
    @Binding var saveName: String
    @Binding var isSavePopupVisible: Bool
    @Binding var isTestActive: Bool
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel // Necesitamos esto para buscar las familias por clave.

    var body: some View {
        VStack(spacing: 16) {
            Text("Guardar Perfil")
                .font(.headline)
                .padding(.top)

            TextField("Nombre del perfil", text: $saveName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            AppButton(
                title: "Guardar",
                action: {
                    Task {
                        await saveProfile()
                    }
                },
                style: .accent,
                size: .large,
                isFullWidth: true,
                icon: "checkmark.circle.fill"
            )
            .padding(.horizontal)

            Button("Cancelar", role: .cancel) {
                isSavePopupVisible = false
            }
        }
        .padding()
    }

    private func saveProfile() async {
        // Buscar la familia principal
        let mainFamilyKey = profile.families.first?.family
        let mainFamily = mainFamilyKey.flatMap { familyViewModel.getFamily(byKey: $0) }

        // Crear el nuevo perfil
        let newProfile = OlfactiveProfile(
            name: saveName.isEmpty ? profile.name : saveName,
            gender: profile.gender,
            families: profile.families,
            intensity: profile.intensity,
            duration: profile.duration,
            descriptionProfile: profile.descriptionProfile,
            icon: profile.icon,
            questionsAndAnswers: profile.questionsAndAnswers,
            orderIndex: -1
        )

        await olfactiveProfileViewModel.addProfile(newProfileData: newProfile)
        isTestActive = false
    }
}
