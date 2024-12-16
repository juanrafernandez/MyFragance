import SwiftUI

struct WelcomeView: View {
    @State private var path: [String] = [] // Maneja el stack de navegación
    @State private var resultsProfile: [String: Double] = [:] // Perfil generado al final

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color("BackgroundColor")
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer()

                    Text("Bienvenido a PerfBeta")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color("TitleColor"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)

                    Text("Descubre tu fragancia ideal")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color("SubtitleDarkerColor"))
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button("Comenzar Test") {
                        path.append("quiz") // Navegamos al test
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Spacer().frame(height: 20)

                    Button("Probar Backend") {
                        path.append("backendTest") // Navegamos al backend test
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationDestination(for: String.self) { value in
                if value == "quiz" {
                    QuizView(path: $path, resultsProfile: $resultsProfile)
                } else if value == "results" {
                    ResultsView(path: $path, profile: resultsProfile)
                }
            }
        }
        .tint(Color.black)
    }
}
