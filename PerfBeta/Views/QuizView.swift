import SwiftUI

struct QuizView: View {
    @Binding var path: [String] // Maneja la navegación
    @Binding var resultsProfile: [String: Double] // Almacena el perfil final
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswers: [UUID: String] = [:]

    let questions: [Question] = MockData.questions

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer().frame(height: 32)

                Text(questions[currentQuestionIndex].text)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TitleColor"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

//                ForEach(questions[currentQuestionIndex].options, id: \.self) { option in
//                    Button(option) {
//                        handleOptionSelection(option)
//                    }
//                    .buttonStyle(PrimaryButtonStyle())
//                }

                Spacer()
            }
        }
        .toolbarRole(.editor)
        .tint(Color("TitleColor"))
    }

    private func handleOptionSelection(_ option: String) {
        let questionID = questions[currentQuestionIndex].id
        //selectedAnswers[questionID] = option

        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            resultsProfile = generateResultsProfile()
            path.append("results") // Navegamos a ResultsView
        }
    }

    private func generateResultsProfile() -> [String: Double] {
        // Procesa las respuestas seleccionadas y genera un perfil de resultados
        var profile: [String: Double] = [:]

        for question in questions {
//            if let answer = selectedAnswers[question.id] {
//                // Asigna un valor a cada respuesta para el gráfico
//                profile[answer] = (profile[answer] ?? 0) + 1
//            }
        }

        // Normaliza los valores a porcentajes
        let totalResponses = Double(profile.values.reduce(0, +))
        for key in profile.keys {
            profile[key] = (profile[key]! / totalResponses) * 100
        }

        return profile
    }
}
