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
                                #if DEBUG
                                print("Google Sign Up Tapped")
                                #endif
                                authViewModel.registerWithGoogle() // <-- CAMBIO
                            }
                        )
                        SocialPlaceholderButton(
                            imageName: "icon_apple",
                            isLoading: authViewModel.isLoadingAppleRegister, // <-- CAMBIO
                            action: {
                                #if DEBUG
                                print("Apple Sign Up Tapped")
                                #endif
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
        }
        .navigationBarHidden(true)
        .alert("Error en el Registro", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("Entendido", role: .cancel) {
                authViewModel.errorMessage = nil
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
        .onTapGesture {
             hideKeyboard()
        }
        .onChange(of: authViewModel.isAuthenticated) {
            if authViewModel.isAuthenticated {
                #if DEBUG
                print("SignUpView: isAuthenticated changed to true, dismissing view.")
                #endif
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
            #if DEBUG
            if success {
                print("SignUpView: Email Registration attempt successful.")
            } else {
                print("SignUpView: Email Registration attempt failed.")
            }
            #endif
        }
    }
}
