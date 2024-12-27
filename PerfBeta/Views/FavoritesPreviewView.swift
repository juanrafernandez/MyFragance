import SwiftUI

struct FavoritesPreviewView: View {
    let perfumes: [Perfume]

    var body: some View {
        ForEach(perfumes, id: \.id) { perfume in
            PerfumeRow(perfume: perfume)
        }
    }
}
