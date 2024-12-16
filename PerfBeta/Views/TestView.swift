import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    @State private var navigateToSummary = false // Controla la navegación a SummaryView

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barra de progreso
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .padding(.top, 10)

                Divider()

                // Pregunta actual
                if !viewModel.questions.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(viewModel.currentQuestion.category)
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(viewModel.currentQuestion.text)
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .padding()

                            ForEach(viewModel.currentQuestion.options) { option in
                                OptionButton(
                                    option: option,
                                    isSelected: viewModel.answers[viewModel.currentQuestion.id]?.value == option.value
                                ) {
                                    handleOptionSelection(option)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("Cargando preguntas...")
                        .font(.headline)
                        .padding()
                }
            }
            .navigationTitle("Test de Perfumes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToSummary) {
                SummaryView(
                    questions: viewModel.questions,
                    answers: viewModel.answers,
                    restartTest: restartTest
                )
                .navigationBarBackButtonHidden(true) // Ocultar botón de navegación
            }
        }
    }

    private func handleOptionSelection(_ option: Option) {
        let isLastQuestion = viewModel.selectOption(option)
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

/// Subcomponente para los botones de opciones
struct OptionButton: View {
    let option: Option
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(option.imageAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color(.primaryButton) : Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .padding(.horizontal)
    }
}
