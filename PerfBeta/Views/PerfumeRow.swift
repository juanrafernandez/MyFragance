import SwiftUI

struct PerfumeRow: View {
    let perfume: Perfume

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(perfume.nombre)
                    .font(.headline)
                Text(perfume.familia.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

