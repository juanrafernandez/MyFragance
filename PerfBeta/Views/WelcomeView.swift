import SwiftUI

struct WelcomeView: View {
    @State private var path: [String] = [] // Maneja el stack de navegación

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Text("Bienvenido a PerfBeta")
                    .font(.title)
                    .padding()
                Text("Descubre tu fragancia ideal")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Button("Comenzar Test") {
                    path.append("quiz") // Navega al test
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)

                Button("Probar Backend") {
                    path.append("backendTest") // Navega a la pantalla de prueba de backend
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            .navigationDestination(for: String.self) { value in
                if value == "quiz" {
                    QuizView(path: $path)
                } else if value == "backendTest" {
                    BackendTestView()
                }
            }
        }
    }
}
