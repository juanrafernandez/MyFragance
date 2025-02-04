import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var message: String = ""
    @State private var showMessage: Bool = false

    var onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Iniciar Sesión")
                .font(.title)
                .padding()

            // Campo de correo
            TextField("Correo Electrónico", text: $email)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Campo de contraseña
            SecureField("Contraseña", text: $password)
                .textContentType(.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Botón para iniciar sesión
            Button(action: signInUser) {
                Text("Iniciar Sesión")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            // Mensaje de error o éxito
            if showMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(message.contains("Error") ? .red : .green)
                    .padding()
            }
        }
        .alert(isPresented: $showMessage) {
            Alert(title: Text("Autenticación"),
                  message: Text(message),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func signInUser() {
        // Validación básica de campos vacíos
//        guard !email.isEmpty, !password.isEmpty else {
//            message = "Por favor, ingresa tu correo y contraseña."
//            showMessage = true
//            return
//        }
//
//        // Llamada al servicio de autenticación
//        AuthService.shared.signInWithEmail(email: email, password: password) { result in
//            switch result {
//            case .success:
//                message = "Inicio de sesión exitoso."
//                onSuccess() // Notifica el éxito
//            case .failure(let error):
//                message = "Error: \(error.localizedDescription)"
//            }
            
            onSuccess()
            showMessage = true
       // }
    }
}
