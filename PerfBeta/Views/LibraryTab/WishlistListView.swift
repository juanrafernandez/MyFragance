import SwiftUI

struct WishlistListView: View {
    @Binding var perfumes: [WishlistItem]

    var body: some View {
        List {
            ForEach(perfumes, id: \.id) { perfume in
                WishListRowView(perfume: perfume)
            }
            .onDelete(perform: deletePerfume)
        }
        .listStyle(.plain) // Optional: Use a plain list style to remove default styling
    }

    func deletePerfume(at offsets: IndexSet) {
        perfumes.remove(atOffsets: offsets)
    }
}
