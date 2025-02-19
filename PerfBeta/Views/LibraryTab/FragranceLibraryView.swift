import SwiftUI

struct FragranceLibraryView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var triedPerfumesManager: TriedPerfumesManager

    @State private var isAddingPerfume = false
    @State private var selectedPerfume: Perfume? = nil

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                GradientView(gradientColors: [Color("champanOscuro").opacity(0.1), Color("champan").opacity(0.1), Color("champanClaro").opacity(0.1),.white])
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Text("Mi Colección")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .horizontal], 16)

                    ScrollView {
                        VStack(spacing: 10) {
                            // Tus Perfumes Probados
                            TriedPerfumesSection(
                                title: "Tus Perfumes Probados",
                                perfumes: triedPerfumesManager.triedPerfumes,
                                maxDisplayCount: 5,
                                addAction: { isAddingPerfume = true },
                                seeMoreDestination: TriedPerfumesListView()
                            )

                            Divider()

                            // Tu Lista de Deseos
                            CompactSectionWithMessage(
                                title: "Tu Lista de Deseos",
                                perfumes: wishlistManager.wishlist,
                                message: "Busca un perfume y pulsa el botón de carrito para añadirlo a tu lista de deseos.",
                                maxDisplayCount: 3,
                                seeMoreDestination: WishlistView()
                            )
                        }
                        .padding()
                    }
                }
                .background(Color.clear)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isAddingPerfume) {
                AddPerfumeOnboardingView(isAddingPerfume: $isAddingPerfume)
                    .onDisappear {
                        if let perfume = selectedPerfume {
                            triedPerfumesManager.addPerfume(perfume)
                        }
                    }
            }
        }
    }
}

// MARK: - Tried Perfumes Section
struct TriedPerfumesSection<Destination: View>: View {
    let title: String
    let perfumes: [Perfume]
    let maxDisplayCount: Int
    let addAction: () -> Void
    let seeMoreDestination: Destination

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                    .bold()
                Spacer()
                if !perfumes.isEmpty {
                    NavigationLink(destination: seeMoreDestination) {
                        Text("Ver más")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.bottom, 5)

            if perfumes.isEmpty {
                // Mostrar mensaje y botón para añadir perfume si la lista está vacía
                VStack (alignment: .center){
                    Text("Aún no has añadido perfumes a esta lista.")
                        .font(.subheadline)
                        .foregroundColor(Color("textoSecundario"))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    Button(action: addAction) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Añadir Perfume")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("champan"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 10)

            } else {
                // Mostrar hasta maxDisplayCount perfumes
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(perfumes.prefix(maxDisplayCount), id: \.id) { perfume in
                        CompactCard(perfume: perfume)
                    }
                }
                // Mostrar botón para añadir perfume debajo de la lista
                Button(action: addAction) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Añadir Perfume")
                            .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("champan"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 10) // Espacio superior para separarlo de la lista
            }
        }
    }
}

// MARK: - Compact Section con mensaje para listas vacías
struct CompactSectionWithMessage<Destination: View>: View {
    let title: String
    let perfumes: [Perfume]
    let message: String
    let maxDisplayCount: Int
    let seeMoreDestination: Destination

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                    .bold()
                Spacer()
                if !perfumes.isEmpty {
                    NavigationLink(destination: seeMoreDestination) {
                        Text("Ver más")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.bottom, 5)

            if perfumes.isEmpty {
                // Mostrar mensaje si la lista está vacía
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
            } else {
                // Mostrar hasta maxDisplayCount perfumes
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(perfumes.prefix(maxDisplayCount), id: \.id) { perfume in
                        CompactCard(perfume: perfume)
                    }
                }
            }
        }
    }
}

// MARK: - Compact Card
struct CompactCard: View {
    let perfume: Perfume

    var body: some View {
        HStack(spacing: 10) {
            Image(perfume.imageURL ?? "placeholder")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 45)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 0) {
                // Nombre del perfume
                Text(perfume.name)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(Color("textoPrincipal"))

                // Fabricante
                Text(perfume.brand)
                    .font(.system(size: 10))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(Color("textoSecundario"))
            }

            Spacer()
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

// MARK: - Pantallas de ejemplo para los enlaces de "Ver más"
struct FavoritesListView: View {
    var body: some View {
        Text("Lista completa de favoritos")
    }
}

struct WishlistView: View {
    var body: some View {
        Text("Lista completa de deseos")
    }
}

struct TriedPerfumesListView: View {
    var body: some View {
        Text("Lista completa de perfumes probados")
    }
}
