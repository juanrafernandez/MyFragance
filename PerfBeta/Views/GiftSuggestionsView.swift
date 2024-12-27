import SwiftUI

struct GiftSuggestionsView: View {
    @ObservedObject var viewModel: GiftRecomendacionViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Perfil recomendado:")
                .font(.headline)

            Text(viewModel.perfilPrincipal?.capitalized ?? "Desconocido")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)
                .padding(.bottom)

            if let perfilSecundario = viewModel.perfilSecundario, !perfilSecundario.isEmpty {
                Text("Complementado por:")
                    .font(.headline)

                Text(perfilSecundario.capitalized)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }

            Text("Fragancias sugeridas:")
                .font(.headline)

            List(viewModel.recomendaciones, id: \.id) { perfume in
                VStack(alignment: .leading, spacing: 8) {
                    Text(perfume.nombre)
                        .font(.headline)
                    Text(perfume.notas.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Familia: \(perfume.familia.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Popularidad: \(String(format: "%.1f", perfume.popularidad))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Sugerencias")
        .padding()
    }
}
