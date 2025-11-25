import SwiftUI

struct SaveProfileView: View {
    let profile: OlfactiveProfile
    @Binding var saveName: String
    @Binding var isSavePopupVisible: Bool
    @Binding var isTestActive: Bool
    let onSaved: (() -> Void)?
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel // Necesitamos esto para buscar las familias por clave.
    @FocusState private var isTextFieldFocused: Bool

    init(
        profile: OlfactiveProfile,
        saveName: Binding<String>,
        isSavePopupVisible: Binding<Bool>,
        isTestActive: Binding<Bool>,
        onSaved: (() -> Void)? = nil
    ) {
        self.profile = profile
        self._saveName = saveName
        self._isSavePopupVisible = isSavePopupVisible
        self._isTestActive = isTestActive
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text("Guardar Perfil")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
                .padding(.top, 8)

            // Campo de texto
            TextField("Nombre del perfil", text: $saveName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await saveProfile()
                    }
                }
                .padding(.horizontal, 20)

            // Botón Guardar
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
            .padding(.horizontal, 20)

            // Botón Cancelar
            Button("Cancelar", role: .cancel) {
                isSavePopupVisible = false
            }
            .padding(.bottom, 8)
        }
        .padding(.vertical, 16)
        .onAppear {
            // Delay to ensure view is fully presented before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
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

        // Llamar al callback de guardado exitoso
        onSaved?()
    }
}
