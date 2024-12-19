import SwiftUI

struct GiftSummaryView: View {
    let preguntas: [Question]
    let respuestas: [String: Option]
    let restartTest: () -> Void

    var body: some View {
        // Código para mostrar el resumen
        VStack {
            Text("Resumen del Test de Regalo")
                .font(.title)
                .padding()

            ScrollView {
                ForEach(preguntas, id: \.id) { pregunta in
                    VStack(alignment: .leading) {
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
                    }
                    .padding()
                }
            }

            Button(action: restartTest) {
                Text("Volver a empezar")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}
