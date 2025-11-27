import SwiftUI

// MARK: - LoginView

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    // ✅ ELIMINADO: Sistema de temas personalizable

    @State private var navigateToSignUp = false

    var body: some View {
        ZStack {
            GradientLinearView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                ZStack {
                    CurvedHeaderShape()
                        .fill(Color.clear)
                        .frame(height: 290)
                        .shadow(radius: 10)

                    LoginHeaderView()
                         .frame(height: 280)
                }
                .zIndex(1)

                VStack(spacing: 20) {

                    IconTextField(iconName: "envelope", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.top, 30)

                    IconTextField(iconName: "lock", placeholder: "Contraseña", text: $password, isSecure: true)

                    HStack {
                        Spacer()
                        Button("¿Olvidaste tu contraseña?") {
                            #if DEBUG
                            print("Forgot Password Tapped")
                            #endif
                        }
                        .font(.footnote)
                        .foregroundColor(AppColor.brandAccent)
                    }

                    AppButton(
                        title: "Login",
                        action: performLogin,
                        style: .primary,
                        size: .large,
                        isLoading: authViewModel.isLoadingEmailLogin,
                        isDisabled: email.isEmpty || password.isEmpty,
                        isFullWidth: true
                    )

                    OrSeparator(text: "O haz login con")
                        .padding(.vertical, 10)

                    HStack(spacing: 25) {
                        SocialPlaceholderButton(
                            imageName: "icon_google",
                            isLoading: authViewModel.isLoadingGoogleLogin,
                            action: {
                                 #if DEBUG
                                 print("Google Login Tapped")
                                 #endif
                                 authViewModel.signInWithGoogle()
                            }
                        )
                        SocialPlaceholderButton(
                            imageName: "icon_apple",
                            isLoading: authViewModel.isLoadingAppleLogin,
                            action: {
                                 #if DEBUG
                                 print("Apple Login Tapped")
                                 #endif
                                 authViewModel.signInWithApple()
                            }
                        )
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("¿No estás Registrado?")
                            .foregroundColor(AppColor.textSecondary)
                         NavigationLink("Regístrate Aquí", destination: SignUpView())
                           .fontWeight(.bold)
                           .foregroundColor(AppColor.brandAccent)
                    }
                    .font(.footnote)
                    .padding(.bottom, AppSpacing.sectionSpacing)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .background(Color.white)
                .clipShape(RoundedCorner(radius: 35, corners: [.topLeft, .topRight]))
                .shadow(radius: 5)

            }
            .frame(maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .navigationBarHidden(true)
        .alert("Error de Inicio de Sesión", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("Entendido", role: .cancel) {
                authViewModel.errorMessage = nil
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
        .onTapGesture {
             hideKeyboard()
        }
        .onAppear {
            PerformanceLogger.logViewAppear("LoginView")
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("LoginView")
        }
    }

    func performLogin() {
        hideKeyboard()
        Task {
            do {
                try await authViewModel.signInWithEmailPassword(email: email, password: password)
            } catch {
                #if DEBUG
                print("Login failed in view: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

struct IconTextField: View {
    var iconName: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray.opacity(0.6))
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
    }
}

struct OrSeparator: View {
    var text: String = "O"
    var body: some View {
        HStack {
            VStack { Divider().background(Color.gray.opacity(0.5)) }
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
            VStack { Divider().background(Color.gray.opacity(0.5)) }
        }
    }
}

struct SocialPlaceholderButton: View {
    let imageName: String
    let isLoading: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                if isLoading {
                    ProgressView()
                } else {
                    Image(imageName)
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                }
            }
            .frame(width: 50, height: 50)
        }
        .disabled(isLoading)
    }
}

// MARK: - Color Extensions removidas
// Migrado a AppColor en DesignTokens.swift

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct LoginHeaderView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Hola!")
                .font(.custom("Georgia", size: 40))
                .tracking(1)
                .foregroundColor(.white)
                .padding(.bottom, 3)
            Text("Bienvenido a Baura")
                .font(.custom("Georgia", size: 25))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
