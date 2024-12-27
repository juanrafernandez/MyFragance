import SwiftUI

struct GiftSummaryView: View {
    let preguntas: [Question]
    let respuestas: [String: Option]
    let restartTest: () -> Void // Closure para reiniciar el test

    var body: some View {
        NavigationView {
            VStack {
                // Título
                Text("Resumen del Test de Regalo")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                    .padding(.horizontal)

                // Lista de preguntas y respuestas
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(preguntas, id: \.id) { pregunta in
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

                                Divider() // Separador entre preguntas
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Botones de acción
                VStack(spacing: 16) {
                    // Navegar a GiftSuggestionsView con los resultados
                    NavigationLink(destination: GiftSuggestionsView(viewModel: GiftRecomendacionViewModel(respuestas: respuestas))) {
                        Text("Obtener Sugerencias")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Botón para reiniciar el test
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
                .padding(.bottom, 40) // Espaciado inferior
            }
            .navigationTitle("Resumen de Respuestas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
