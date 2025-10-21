import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var name = ""
    // ✅ ELIMINADO: Sistema de temas personalizable

    var body: some View {
        ZStack {
            GradientLinearView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                 HStack {
                     Button { dismiss() } label: {
                         Image(systemName: "arrow.left")
                             .foregroundColor(.white)
                         Text("Volver al Login")
                              .foregroundColor(.white)
                     }
                     Spacer()
                 }
                 .padding()
                 .padding(.top, 40)

                VStack(spacing: 20) {
                    Text("Crear Cuenta")
                        .font(.title.bold())
                        .padding(.top, 30)

                    IconTextField(iconName: "person", placeholder: "Nombre", text: $name)
                    IconTextField(iconName: "envelope", placeholder: "Email", text: $email)
                         .keyboardType(.emailAddress)
                         .textInputAutocapitalization(.never)
                         .autocorrectionDisabled(true)
                    IconTextField(iconName: "lock", placeholder: "Contraseña", text: $password, isSecure: true)
                    IconTextField(iconName: "lock.fill", placeholder: "Confirmar Contraseña", text: $confirmPassword, isSecure: true)

                    Spacer().frame(height: 10)

                    AppButton(
                        title: "Crear Cuenta",
                        action: performSignUp,
                        style: .primary,
                        size: .large,
                        isLoading: authViewModel.isLoadingEmailRegister,
                        isDisabled: email.isEmpty || password.isEmpty || name.isEmpty || password != confirmPassword,
                        isFullWidth: true
                    )


                    OrSeparator(text: "O regístrate con")
                        .padding(.vertical, 10)

                    HStack(spacing: 25) {
                        SocialPlaceholderButton(
                            imageName: "icon_google",
                            isLoading: authViewModel.isLoadingGoogleRegister, // <-- CAMBIO
                            action: {
                                print("Google Sign Up Tapped")
                                authViewModel.registerWithGoogle() // <-- CAMBIO
                            }
                        )
                        SocialPlaceholderButton(
                            imageName: "icon_apple",
                            isLoading: authViewModel.isLoadingAppleRegister, // <-- CAMBIO
                            action: {
                                print("Apple Sign Up Tapped")
                                authViewModel.registerWithApple() // <-- CAMBIO
                            }
                        )
                    }

                    Spacer()

                    HStack(spacing: 4) {
                         Text("¿Ya tienes cuenta?")
                             .foregroundColor(.textSecondaryNew)
                         Button("Inicia Sesión Aquí") {
                             dismiss()
                         }
                         .fontWeight(.bold)
                         .foregroundColor(.primaryButton)
                     }
                     .font(.footnote)
                     .padding(.bottom, 35)

                }
                .padding(.horizontal, 30)
                .background(Color.white)
                .clipShape(RoundedCorner(radius: 35, corners: [.topLeft, .topRight]))
                .shadow(radius: 5)

            }
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(.container, edges: .bottom)

            // MARK: - Error View (NUEVO - Reemplaza alert)
            if let errorMessage = authViewModel.errorMessage {
                ErrorView(
                    error: AppError.from(NSError(
                        domain: "SignUpError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errorMessage]
                    )),
                    retryAction: {
                        // Retry último intento de registro
                        performSignUp()
                    },
                    dismissAction: {
                        authViewModel.errorMessage = nil
                    }
                )
                .background(Color.white.opacity(0.98))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: authViewModel.errorMessage)
        .onTapGesture {
             hideKeyboard()
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                print("SignUpView: isAuthenticated changed to true, dismissing view.")
                dismiss()
            }
        }
        .onAppear {
            PerformanceLogger.logViewAppear("SignUpView")
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("SignUpView")
        }
    }

    func performSignUp() {
        guard password == confirmPassword else {
            Task { @MainActor in
                 authViewModel.errorMessage = "Las contraseñas no coinciden."
            }
            return
        }
        hideKeyboard()

        Task {
            // Llamamos a la función de registro con email del ViewModel
            let success = await authViewModel.registerUserWithEmail( // <-- CAMBIO (Usar función renombrada)
                email: email,
                password: password,
                name: name
            )
            if success {
                print("SignUpView: Email Registration attempt successful.")
            } else {
                print("SignUpView: Email Registration attempt failed.")
            }
        }
    }
}
