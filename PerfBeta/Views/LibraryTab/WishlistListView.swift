import SwiftUI

struct WishlistListView: View {
    @Binding var perfumes: [WishlistItem]
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.editMode) private var editMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            List {
                ForEach(perfumes, id: \.id) { perfume in
                    WishListRowView(perfume: perfume)
                        .listRowSeparator(.hidden)
                }
                .onDelete(perform: deletePerfume)
                .onMove(perform: movePerfume)
            }
            .listStyle(.plain)
        }
        
        .navigationTitle("Lista de deseos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }

    func deletePerfume(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { perfumes[$0] }

        perfumes.remove(atOffsets: offsets)

        Task {
            for item in itemsToDelete {
                await userViewModel.removeFromWishlist(userId: "testUserId", wishlistItem: item)
            }

            await updateOrderAfterModification(userId: "testUserId")
        }
    }

    func movePerfume(from source: IndexSet, to destination: Int) {
        // 1. Mueve en el array local (UI se actualiza por @Binding)
        perfumes.move(fromOffsets: source, toOffset: destination)

        Task {
            // Pasa la lista local (ya reordenada y con índices actualizados) al ViewModel
            await userViewModel.updateWishlistOrder(userId: "testUserId", orderedPerfumes: perfumes)
        }
    }

    // Llama a la función del ViewModel para guardar el orden actual
    // después de una modificación como eliminar.
    private func updateOrderAfterModification(userId: String) async {
        // Llama al ViewModel para guardar este estado actual en el backend
        await userViewModel.updateWishlistOrder(userId: userId, orderedPerfumes: perfumes)
    }
}
