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
        VStack(spacing: 16) {
            // Título
            Text("Guardar Perfil")
                .font(.custom("Georgia", size: 20))
                .foregroundColor(AppColor.textPrimary)

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
            Button(action: {
                isSavePopupVisible = false
            }) {
                Text("Cancelar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Delay to ensure view is fully presented before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

    private func saveProfile() async {
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

        // Cerrar el bottom sheet y el test en el main thread
        await MainActor.run {
            isSavePopupVisible = false
            isTestActive = false
            onSaved?()
        }
    }
}

// MARK: - SaveGiftProfileSheet

/// Sheet para guardar un perfil de regalo
struct SaveGiftProfileSheet: View {
    @Binding var saveName: String
    @Binding var isSavePopupVisible: Bool
    let onSaved: (() -> Void)?

    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Título
            Text("Guardar Perfil de Regalo")
                .font(.custom("Georgia", size: 20))
                .foregroundColor(AppColor.textPrimary)

            // Campo de texto
            TextField("Nombre del destinatario", text: $saveName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await saveGiftProfile()
                    }
                }
                .padding(.horizontal, 20)

            // Botón Guardar
            AppButton(
                title: "Guardar",
                action: {
                    Task {
                        await saveGiftProfile()
                    }
                },
                style: .accent,
                size: .large,
                isFullWidth: true,
                icon: "checkmark.circle.fill"
            )
            .padding(.horizontal, 20)

            // Botón Cancelar
            Button(action: {
                isSavePopupVisible = false
            }) {
                Text("Cancelar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }

    private func saveGiftProfile() async {
        let nickname = saveName.isEmpty ? "Regalo" : saveName
        await giftRecommendationViewModel.saveProfile(nickname: nickname)

        await MainActor.run {
            isSavePopupVisible = false
            onSaved?()
        }
    }
}
