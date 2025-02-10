import SwiftUI

struct FragranceLibraryView: View {
    @EnvironmentObject var wishlistManager: WishlistManager // Acceso al manager de la lista de deseos
    @EnvironmentObject var triedPerfumesManager: TriedPerfumesManager // Acceso al manager de perfumes probados

    @State private var isAddingPerfume = false // Controla si se está mostrando AddPerfumeFlowView
    @State private var selectedPerfume: Perfume? = nil // Perfume seleccionado en el proceso de añadir

    var body: some View {
        NavigationView {
            VStack {
                Text("Mi Perfumería")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("textoPrincipal"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .horizontal], 16)

                ScrollView {
                    VStack(spacing: 10) {
                        // Tus Perfumes Probados
                        CompactSectionWithAdd(
                            title: "Tus Perfumes Probados",
                            perfumes: triedPerfumesManager.triedPerfumes, // Usar lista compartida
                            addAction: {
                                isAddingPerfume = true // Mostrar la interfaz de añadir perfume
                            },
                            seeMoreDestination: TriedPerfumesListView()
                        )

                        Divider()

                        // Tu Lista de Deseos
                        CompactSectionWithMessage(
                            title: "Tu Lista de Deseos",
                            perfumes: wishlistManager.wishlist,
                            message: "Busca un perfume y pulsa el botón de carrito para añadirlo a tu lista de deseos.",
                            seeMoreDestination: WishlistView()
                        )
                    }
                    .padding()
                }
            }
            .background(Color("fondoClaro"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isAddingPerfume) {
                AddPerfumeFlowView(selectedPerfume: $selectedPerfume)
                    .onDisappear {
                        // Actualización tras cerrar el flujo de añadir
                        if let perfume = selectedPerfume {
                            triedPerfumesManager.addPerfume(perfume)
                        }
                    }
            }
        }
    }
}

// MARK: - Compact Section con mensaje para listas vacías
struct CompactSectionWithMessage<Destination: View>: View {
    let title: String
    let perfumes: [Perfume]
    let message: String
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
                // Mostrar hasta 4 perfumes
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(perfumes.prefix(4), id: \.id) { perfume in
                        CompactCard(perfume: perfume)
                    }
                }
            }
        }
    }
}

// MARK: - Compact Section con botón para añadir
struct CompactSectionWithAdd<Destination: View>: View {
    let title: String
    let perfumes: [Perfume]
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
                // Mostrar botón para añadir perfume si la lista está vacía
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
                .padding(.top, 10)
            } else {
                // Mostrar hasta 4 perfumes
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(perfumes.prefix(4), id: \.id) { perfume in
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
                    .truncationMode(.tail) // Se asegura de truncar solo al final
                    .foregroundColor(Color("textoPrincipal"))

                // Fabricante
                Text(perfume.brand)
                    .font(.system(size: 10))
                    .lineLimit(2)
                    .truncationMode(.tail) // Aplica el mismo ajuste al fabricante
                    .foregroundColor(Color("textoSecundario"))
            }

            Spacer() // Empuja los textos hacia la izquierda para que ocupen todo el espacio disponible
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
