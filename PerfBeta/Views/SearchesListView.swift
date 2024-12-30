import SwiftUI

struct SearchesListView: View {
    @Binding var recentSearches: [GiftSearch]

    var body: some View {
        List {
            ForEach(recentSearches) { search in
                Text(search.name)
            }
            .onDelete { indexSet in
                recentSearches.remove(atOffsets: indexSet)
            }
            .onMove { indices, newOffset in
                recentSearches.move(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .navigationTitle("Búsquedas Guardadas")
        .navigationBarItems(trailing: EditButton())
    }
}
