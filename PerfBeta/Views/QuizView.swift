import SwiftUI

struct QuizView: View {
    @Binding var path: [String] // Maneja el stack de navegación
    @State private var currentQuestionIndex = 0
    @State private var answers: [String] = []
    @State private var showResults = false

    let questions = MockData.questions
    @ObservedObject var viewModel = QuizViewModel()

    var body: some View {
        VStack {
            if currentQuestionIndex < questions.count {
                Text(questions[currentQuestionIndex].text)
                    .font(.headline)
                    .padding()

                ForEach(questions[currentQuestionIndex].options, id: \.self) { option in
                    Button(action: {
                        answers.append(option)
                        currentQuestionIndex += 1

                        if currentQuestionIndex == questions.count {
                            viewModel.answers = answers
                            showResults = true
                        }
                    }) {
                        Text(option)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("¡Gracias por completar el test!")
                    .font(.title)
                    .padding()
            }
        }
        .sheet(isPresented: $showResults) {
            ResultsView(path: $path, profile: viewModel.calculateProfile())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
    }
}
