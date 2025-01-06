import SwiftUI

struct GiftSuggestionsView: View {
    @Binding var isTestOlfativoActive: Bool // Binding para cerrar todas las vistas
    @EnvironmentObject var giftManager: GiftManager
    @EnvironmentObject var familiaOlfativaManager: FamiliaOlfativaManager

    @State private var searchName: String = ""
    @State private var showSavePrompt = false

    let preguntas: [Question]
    let respuestas: [String: Option]
    @ObservedObject var viewModel: GiftRecomendacionViewModel

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(preguntas, id: \.id) { pregunta in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pregunta.text)
                                .font(.headline)
                            if let respuesta = respuestas[pregunta.id] {
                                Text(respuesta.label ?? "")
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

            Divider()
                .padding(.vertical)

            VStack(spacing: 16) {
                Text("Tu Perfil de Regalo")
                    .font(.headline)

                Text(viewModel.perfilPrincipal?.capitalized ?? "Desconocido")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let perfilSecundario = viewModel.perfilSecundario, !perfilSecundario.isEmpty {
                    Text("Complementado por \(perfilSecundario.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                List(viewModel.recomendaciones, id: \.id) { perfume in
                    HStack {
                        Image(perfume.imagenURL)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        VStack(alignment: .leading) {
                            Text(perfume.nombre)
                                .font(.headline)
                            Text(perfume.notasPrincipales.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Familia: \(perfume.familia.capitalized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
            }
            .padding(.horizontal)

            Spacer()

            Button(action: {
                showSavePrompt = true
            }) {
                Text("Guardar Búsqueda")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitle("Resumen y Sugerencias", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isTestOlfativoActive = false // Cerrar hasta la pantalla raíz
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Guardar Búsqueda", isPresented: $showSavePrompt) {
            TextField("Nombre de la búsqueda (máx. 15 caracteres)", text: $searchName)
                .onChange(of: searchName) { oldValue, newValue in
                    if newValue.count > 15 {
                        searchName = String(newValue.prefix(15))
                    }
                }
            Button("Guardar") {
                saveSearch()
                isTestOlfativoActive = false // Cerrar hasta la pantalla raíz
            }
            Button("Cancelar", role: .cancel) { }
        }
    }

    private func saveSearch() {
        let familiaId = viewModel.perfilPrincipal ?? "desconocido"
        let familia = familiaOlfativaManager.getFamilia(byID: familiaId) ?? FamiliaOlfativa(
            id: "desconocido",
            nombre: "Desconocido",
            descripcion: "Descripción predeterminada.",
            notasClave: [],
            ingredientesAsociados: [],
            intensidadPromedio: "Media",
            estacionRecomendada: [],
            personalidadAsociada: [],
            ocasion: [],
            color: "#CCCCCC"
        )

        let newSearch = GiftSearch(
            id: UUID(),
            name: searchName,
            perfumes: viewModel.recomendaciones,
            familia: familia,
            description: "Basado en \(familia.nombre)",
            icon: "icon_default",
            questionsAndAnswers: [] // Pasar un valor vacío si no tienes datos aún
        )

        giftManager.addSearch(newSearch)
    }
}
