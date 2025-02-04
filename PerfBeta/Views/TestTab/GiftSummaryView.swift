import SwiftUI

struct GiftSummaryView: View {
    let preguntas: [Question]
    let respuestas: [String: Option]
    let restartTest: () -> Void
    @State private var isGiftSearchActive: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                titleView
                questionsListView
                Spacer()
                actionButtons
            }
            .navigationTitle("Resumen de Respuestas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Título del test
    private var titleView: some View {
        Text("Resumen del Test de Regalo")
            .font(.largeTitle)
            .bold()
            .padding(.top)
            .padding(.horizontal)
    }

    // Lista de preguntas y respuestas
    private var questionsListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(preguntas, id: \.id) { pregunta in
                    questionAnswerView(for: pregunta)
                }
            }
            .padding(.horizontal)
        }
    }

    // Pregunta y respuesta individual
    private func questionAnswerView(for pregunta: Question) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pregunta.text)
                .font(.headline)
            
            if let respuesta = respuestas[pregunta.id] {
                Text(respuesta.label)
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

    // Botones de acción
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                restartTest()
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

