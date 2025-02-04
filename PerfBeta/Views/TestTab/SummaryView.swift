import SwiftUI

struct SummaryView: View {
    let questions: [Question]
    let answers: [String: Option]
    let restartTest: () -> Void
    @Binding var isTestActive: Bool

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                questionListView
                actionButtons
            }
            .navigationTitle("Resumen de Respuestas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        Text("Resumen de Respuestas")
            .font(.largeTitle)
            .bold()
            .padding(.top)
            .padding(.horizontal)
    }

    private var questionListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(questions) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.text)
                            .font(.headline)

                        if let selectedOption = answers[question.id] {
                            Text(selectedOption.label)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Sin respuesta")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }

                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            NavigationLink(destination: SuggestionsView(
                isTestActive: $isTestActive,
                questions: questions,
                answers: answers
            )) {
                Text("Obtener Sugerencias")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                restartTest()
                isTestActive = false
            }) {
                Text("Volver a empezar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 40)
    }
}
