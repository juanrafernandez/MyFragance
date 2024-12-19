import SwiftUI

struct GiftView: View {
    @StateObject private var viewModel = GiftViewModel()
    @State private var navigateToSummary = false // Controla la navegación a GiftSummaryView

    var body: some View {
        VStack(spacing: 0) {
            // Barra de progreso
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .padding(.horizontal)
                .padding(.top, 10)

            Divider()

            // Pregunta actual
            if let currentQuestion = viewModel.currentQuestion {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(currentQuestion.category)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(currentQuestion.text)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding()

                        ForEach(currentQuestion.options) { option in
                            OptionButton(
                                option: option,
                                isSelected: viewModel.answers[currentQuestion.id]?.value == option.value
                            ) {
                                handleOptionSelection(option)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                // Estado de carga mientras se obtienen las preguntas
                Text("Cargando preguntas...")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationTitle("Test de Regalo")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSummary) {
            GiftSummaryView(
                preguntas: viewModel.preguntasRelevantes,
                respuestas: viewModel.answers,
                restartTest: restartTest
            )
            .navigationBarBackButtonHidden(true) // Ocultar botón de navegación
        }
    }

    private func handleOptionSelection(_ option: Option) {
        let isLastQuestion = viewModel.seleccionarOpcion(option)
        if isLastQuestion {
            navigateToSummary = true
        }
    }

    private func restartTest() {
        viewModel.currentQuestionIndex = 0
        viewModel.answers.removeAll()
        navigateToSummary = false
    }
}
