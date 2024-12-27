import SwiftUI

struct FragranceLibraryView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    CompactSection(
                        title: "Tus Perfumes Favoritos",
                        perfumes: MockPerfumes.perfumes,
                        seeMoreDestination: FavoritesListView(),
                        addAction: {
                            print("Agregar perfume a favoritos")
                        }
                    )

                    Divider()

                    CompactSection(
                        title: "Tus Perfumes Probados",
                        perfumes: MockPerfumes.perfumes,
                        seeMoreDestination: TriedPerfumesListView(),
                        addAction: {
                            print("Agregar perfume a probados")
                        }
                    )

                    Divider()

                    CompactSection(
                        title: "Tu Lista de Deseos",
                        perfumes: MockPerfumes.perfumes,
                        seeMoreDestination: WishlistView(),
                        addAction: {
                            print("Agregar perfume a lista de deseos")
                        }
                    )
                }
                .padding()
                .navigationTitle("Mi Perfumería")
            }
        }
    }
}

struct CompactSection<Destination: View>: View {
    let title: String
    let perfumes: [Perfume]
    let seeMoreDestination: Destination
    let addAction: () -> Void // Acción para el botón de agregar

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                    .bold()
                Spacer()
                NavigationLink(destination: seeMoreDestination) {
                    Text("Ver más")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
            }
            .padding(.bottom, 5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(perfumes.prefix(3), id: \.id) { perfume in
                    CompactCard(perfume: perfume)
                }

                // Botón para añadir un perfume
                Button(action: addAction) {
                    VStack {
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct CompactCard: View {
    let perfume: Perfume

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(perfume.nombre)
                .font(.subheadline)
                .bold()
            Text(perfume.familia.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}


struct CompactTableSection<Destination: View>: View {
    let title: String
    let perfumes: [Perfume]
    let seeMoreDestination: Destination

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                NavigationLink(destination: seeMoreDestination) {
                    Text("Ver más")
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 5)

            Table {
                ForEach(perfumes, id: \.id) { perfume in
                    TableRow(perfume: perfume)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct Table<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 1) {
            content
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct TableRow: View {
    let perfume: Perfume

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(perfume.nombre)
                    .font(.subheadline)
                Text(perfume.familia.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(UIColor.systemBackground))
    }
}


struct FavoritesListView: View {
    var body: some View {
        Text("Lista completa de favoritos")
    }
}

struct TriedPerfumesListView: View {
    var body: some View {
        Text("Lista completa de perfumes probados")
    }
}

struct WishlistView: View {
    var body: some View {
        Text("Lista completa de deseos")
    }
}
