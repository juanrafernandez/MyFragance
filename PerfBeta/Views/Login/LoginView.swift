import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    @State private var navigateToSignUp = false

    var body: some View {
        ZStack {
            GradientLinearView(preset: selectedGradientPreset)
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
                            print("Forgot Password Tapped")
                        }
                        .font(.footnote)
                        .foregroundColor(.primaryButton)
                    }

                    Button(action: performLogin) {
                        if authViewModel.isLoadingEmailLogin {
                            ProgressView().tint(.white)
                        } else {
                            Text("Login")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(authViewModel.isLoadingEmailLogin || email.isEmpty || password.isEmpty)

                    OrSeparator(text: "O haz login con")
                        .padding(.vertical, 10)

                    HStack(spacing: 25) {
                        SocialPlaceholderButton(
                            imageName: "icon_google",
                            isLoading: authViewModel.isLoadingGoogleLogin,
                            action: {
                                 print("Google Login Tapped")
                                 authViewModel.signInWithGoogle()
                            }
                        )
                        SocialPlaceholderButton(
                            imageName: "icon_apple",
                            isLoading: authViewModel.isLoadingAppleLogin,
                            action: {
                                 print("Apple Login Tapped")
                                 authViewModel.signInWithApple()
                            }
                        )
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("¿No estás Registrado?")
                            .foregroundColor(.textSecondaryNew)
                         NavigationLink("Regístrate Aquí", destination: SignUpView())
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
                        domain: "LoginError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errorMessage]
                    )),
                    retryAction: {
                        // Retry último intento de login
                        performLogin()
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
                print("Login failed in view: \(error.localizedDescription)")
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

extension Color {
    static let textSecondaryNew = Color.gray
    static let themeBackgroundNew = Color(.systemBackground)
    static let cardBackgroundNew = Color(.systemBackground)
    static let textFieldBorderNew = Color(uiColor: .systemGray5)
    static let placeholderTextNew = Color(uiColor: .systemGray)
    static let iconColorNew = Color(uiColor: .systemGray2)
    static let textPrimaryNew = Color.primary
    static let textOnPrimaryButtonNew = Color.white
}

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
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.white)
                .padding(.bottom, 3)
            Text("Bienvenido a My Fragance")
                .font(.system(size: 25, weight: .thin))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
