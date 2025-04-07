import SwiftUI

struct PerfumeRow: View {
    let perfume: Perfume

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(perfume.name)
                    .font(.headline)
                Text(perfume.family.capitalized)
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

