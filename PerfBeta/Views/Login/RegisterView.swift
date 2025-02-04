import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var nombre = ""
    @State private var showMessage = false
    @State private var message = ""
    
    private let authService = AuthService.shared
    
    var body: some View {
        VStack {
            Text("Registro de Usuario")
                .font(.title)
                .padding()

            TextField("Nombre", text: $nombre)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .autocapitalization(.words)

            TextField("Correo Electrónico", text: $email)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Contraseña", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Button(action: {
                registerUser()
            }) {
                Text("Registrarse")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top)

            if showMessage {
                Text(message)
                    .foregroundColor(.green)
                    .padding(.top)
            }

            Spacer()
        }
        .padding()
    }

    private func registerUser() {
        authService.registerUser(email: email, password: password, nombre: nombre) { result in
            switch result {
            case .success:
                message = "Usuario registrado exitosamente"
            case .failure(let error):
                message = "Error: \(error.localizedDescription)"
            }
            showMessage = true
        }
    }
}
