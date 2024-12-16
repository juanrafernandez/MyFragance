import SwiftUI

struct SuggestionsView: View {
    @ObservedObject var viewModel: RecomendacionViewModel

    var body: some View {
        VStack {
            Text("Tu perfil olfativo principal es:")
                .font(.headline)
            Text(viewModel.perfilPrincipal.capitalized)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)
                .padding(.bottom)

            Text("Complementado por:")
                .font(.headline)
            Text(viewModel.perfilSecundario.capitalized)
                .font(.title2)
                .bold()
                .foregroundColor(.gray)
                .padding(.bottom)

            List(viewModel.puntajes.sorted(by: { $0.value > $1.value }), id: \.key) { familia, puntos in
                VStack(alignment: .leading) {
                    Text(familia.capitalized)
                        .font(.headline)
                    Text("Puntos: \(puntos)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Sugerencias")
    }
}

