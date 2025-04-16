import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // You'll need register function here
    @Environment(\.dismiss) var dismiss // To go back programmatically if needed

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phone = "" // Add if needed by your logic
    @State private var name = "" // Assuming you need name for registration

    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                 // Simple Header or use Navigation Bar if preferred
                 // For this design, maybe a simpler top bar is better
                 HStack {
                     Button { dismiss() } label: { // Use the environment dismiss action
                         Image(systemName: "arrow.left")
                         Text("Back to login")
                     }
                     .foregroundColor(Color.tealHeader) // Or .white if on teal background
                     Spacer()
                 }
                 .padding()
                 .padding(.top, 40) // Adjust for safe area
                // If you want a teal header like Login, add it here

                // White Content Card
                VStack(spacing: 20) {
                    Text("Sign Up")
                        .font(.title.bold())
                        .padding(.top, 30)

                    IconTextField(iconName: "person", placeholder: "Name", text: $name) // Add Name field
                    IconTextField(iconName: "envelope", placeholder: "Email", text: $email)
                         .keyboardType(.emailAddress)
                    IconTextField(iconName: "lock", placeholder: "Password", text: $password, isSecure: true)
                    IconTextField(iconName: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                    IconTextField(iconName: "phone", placeholder: "Phone (Optional)", text: $phone) // Make optional if needed
                        .keyboardType(.phonePad)

                    Spacer().frame(height: 10) // Add some space

                    Button(action: performSignUp) {
                        if authViewModel.isLoading { // Assuming isLoading covers registration too
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign Up")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty || name.isEmpty || password != confirmPassword) // Add validation

                    Spacer() // Push content up

                }
                .padding(.horizontal, 30)
                .background(Color.white)
                .cornerRadius(35) // Full rounded corners for Sign Up card seem okay here
                .padding(.top, 20) // Space from the simple header
                .shadow(radius: 5)


                Spacer() // Pushes card up if content is short
            }
        }
        .navigationBarHidden(true) // Hide default nav bar
         .alert("Registration Error", isPresented: Binding(
            get: { authViewModel.errorMessage != nil },
            set: { _ in authViewModel.errorMessage = nil }
        ), presenting: authViewModel.errorMessage) { message in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    func performSignUp() {
        guard password == confirmPassword else {
            authViewModel.errorMessage = "Passwords do not match."
            return
        }
        hideKeyboard()
        Task {
            do {
                // *** You need to add a registration method to AuthViewModel ***
                // Example: try await authViewModel.registerUser(...)
                // It should call authService.registerUser and handle loading/errors
                // similar to signInWithEmailPassword
                try await authViewModel.registerUser(
                    email: email,
                    password: password,
                    name: name // Pass other required fields
                    // phone: phone // if needed
                )
                // Success - Listener will update state, ContentView will switch view
            } catch {
                // Error is handled by the .alert modifier
                print("Sign up failed in view: \(error.localizedDescription)")
            }
        }
    }
}

// --- You'll need to add this to AuthViewModel ---
extension AuthViewModel {
    func registerUser(email: String, password: String, name: String) async throws { // Add other params as needed
        isLoading = true
        errorMessage = nil
        do {
            // Assuming your AuthService has registerUser(email:password:nombre:rol:)
            try await authService.registerUser(email: email, password: password, nombre: name, rol: "usuario") // Adjust params as needed
            print("AuthViewModel: registerUser successful request sent. Listener will handle state change.")
             isLoading = false
        } catch {
            print("AuthViewModel: Error during registerUser - \(error.localizedDescription)")
            self.errorMessage = mapAuthErrorToMessage(error) // Reuse error mapping
            self.isLoading = false
            throw error
        }
    }
}