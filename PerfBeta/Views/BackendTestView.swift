import SwiftUI

struct BackendTestView: View {
    @State private var message: String? // Mensaje del Toast
    @State private var showMessage = false // Controla la visibilidad del Toast

    var body: some View {
        ZStack {
            VStack {
                Text("Probar Backend")
                    .font(.title)
                    .padding()

                // Botón para probar "Agregar Perfume"
                Button("Agregar Perfume de Prueba") {
                    let perfume = Perfume(id: nil, nombre: "Perfume Prueba", familia: "Cítrica", popularidad: 8.0, notas: ["Limón", "Mandarina"])
                    FirestoreService().addPerfume(perfume: perfume) { result in
                        switch result {
                        case .success:
                            showFeedback(message: "Perfume agregado correctamente")
                        case .failure(let error):
                            showFeedback(message: "Error: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(BackendButtonStyle(color: .green))

                // Botón para probar "Leer Perfumes"
                Button("Leer Perfumes") {
                    FirestoreService().getPerfumes { result in
                        switch result {
                        case .success(let perfumes):
                            showFeedback(message: "Perfumes obtenidos: \(perfumes.map { $0.nombre }.joined(separator: ", "))")
                        case .failure(let error):
                            showFeedback(message: "Error: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(BackendButtonStyle(color: .blue))

                // Botón para probar "Actualizar Perfume"
                Button("Actualizar Perfume (Mock ID)") {
                    FirestoreService().updatePerfume(documentId: "mockId123", updatedData: ["popularidad": 9.5]) { result in
                        switch result {
                        case .success:
                            showFeedback(message: "Perfume actualizado correctamente")
                        case .failure(let error):
                            showFeedback(message: "Error: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(BackendButtonStyle(color: .orange))

                // Botón para probar "Eliminar Perfume"
                Button("Eliminar Perfume (Mock ID)") {
                    FirestoreService().deletePerfume(documentId: "mockId123") { result in
                        switch result {
                        case .success:
                            showFeedback(message: "Perfume eliminado correctamente")
                        case .failure(let error):
                            showFeedback(message: "Error: \(error.localizedDescription)")
                        }
                    }
                }
                .buttonStyle(BackendButtonStyle(color: .red))

                Spacer()
            }
            .padding()

            // Toast
            if showMessage, let message = message {
                Text(message)
                    .font(.body)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showMessage = false
                            }
                        }
                    }
            }
        }
    }

    // Muestra un mensaje temporal
    private func showFeedback(message: String) {
        self.message = message
        withAnimation {
            self.showMessage = true
        }
    }
}

// Estilo para botones de prueba
struct BackendButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
