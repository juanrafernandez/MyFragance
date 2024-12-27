import SwiftUI

struct WishlistPreviewView: View {
    let perfumes: [Perfume]

    var body: some View {
        ForEach(perfumes, id: \.id) { perfume in
            PerfumeRow(perfume: perfume)
        }
    }
}
