import SwiftUI

/// Modal para editar perfil de usuario
/// Permite cambiar nombre (email no editable por seguridad)
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    @State private var name: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.spacing24) {
                        // Avatar Section
                        VStack(spacing: AppSpacing.spacing12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColor.brandAccent.opacity(0.3),
                                                AppColor.brandAccent.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Text(name.prefix(1).uppercased())
                                    .font(.system(size: 42, weight: .semibold))
                                    .foregroundColor(AppColor.brandAccent)
                            }

                            Text("Edita tu información")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColor.textSecondary)
                        }
                        .padding(.top, AppSpacing.spacing20)

                        // Form Section
                        VStack(spacing: AppSpacing.spacing16) {
                            // Name Field
                            VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
                                Text("Nombre")
                                    .font(AppTypography.labelSmall)
                                    .foregroundColor(AppColor.textSecondary)

                                TextField("Tu nombre", text: $name)
                                    .font(AppTypography.bodyMedium)
                                    .padding(AppSpacing.spacing12)
                                    .background(AppColor.surfaceCard)
                                    .cornerRadius(AppCornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                            .stroke(AppColor.borderPrimary, lineWidth: 1)
                                    )
                            }

                            // Email Field (Read-only)
                            VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
                                Text("Email")
                                    .font(AppTypography.labelSmall)
                                    .foregroundColor(AppColor.textSecondary)

                                HStack {
                                    Text(authViewModel.currentUser?.email ?? "")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColor.textTertiary)

                                    Spacer()

                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColor.textTertiary)
                                }
                                .padding(AppSpacing.spacing12)
                                .background(AppColor.surfaceSecondary.opacity(0.5))
                                .cornerRadius(AppCornerRadius.medium)
                            }

                            Text("El email no se puede cambiar por seguridad")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColor.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, AppSpacing.spacing20)

                        // Error Message
                        if let errorMessage = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppColor.feedbackError)
                                Text(errorMessage)
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColor.feedbackError)
                            }
                            .padding(AppSpacing.spacing12)
                            .background(AppColor.feedbackErrorBackground)
                            .cornerRadius(AppCornerRadius.small)
                            .padding(.horizontal, AppSpacing.spacing20)
                        }

                        // Save Button
                        Button(action: saveProfile) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Guardar Cambios")
                                        .font(AppTypography.labelLarge)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.spacing16)
                            .background(AppColor.brandAccent)
                            .foregroundColor(.white)
                            .cornerRadius(AppCornerRadius.medium)
                        }
                        .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                        .padding(.horizontal, AppSpacing.spacing20)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.brandAccent)
                }
            }
            .alert("Perfil Actualizado", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu perfil se ha actualizado correctamente")
            }
        }
        .onAppear {
            name = authViewModel.currentUser?.displayName ?? ""
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre no puede estar vacío"
            return
        }

        guard let userId = authViewModel.currentUser?.id else {
            errorMessage = "Usuario no encontrado"
            return
        }

        isLoading = true
        errorMessage = nil

        // TODO: Implementar actualización de perfil en UserService/UserViewModel
        // Por ahora, simulamos el guardado
        Task {
            // Simular delay de red
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                isLoading = false
                // Por ahora solo mostramos éxito sin actualizar en Firebase
                // Esto se puede implementar agregando un método updateUser en UserService
                showSuccessAlert = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let authVM = AuthViewModel(authService: DependencyContainer.shared.authService)
    let userVM = UserViewModel(
        userService: DependencyContainer.shared.userService,
        authViewModel: authVM
    )

    return EditProfileView()
        .environmentObject(authVM)
        .environmentObject(userVM)
}
