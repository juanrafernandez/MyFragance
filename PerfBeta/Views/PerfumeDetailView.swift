import SwiftUI

struct PerfumeDetailView: View {
    @Environment(\.presentationMode) var presentationMode // Para cerrar la interfaz
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var wishlistManager: WishlistManager

    let perfume: Perfume
    let relatedPerfumes: [Perfume] // Lista de perfumes relacionados

    @State private var showRemoveFromFavoritesAlert = false
    @State private var showRemoveFromWishlistAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Imagen, Nombre, Fabricante y Descripción Olfativa
                    HStack(spacing: 16) {
                        Image(perfume.image_name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(perfume.nombre)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("textoPrincipal"))

                            Text(perfume.fabricante)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Descripción: \(perfume.familia.capitalized)")
                                .font(.subheadline)
                                .foregroundColor(Color("textoSecundario"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    // Pirámide Olfativa
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pirámide Olfativa")
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))

                        Text("Notas de Salida: \(perfume.notas.prefix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        Text("Notas de Corazón: \(perfume.notas.dropFirst(2).prefix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        Text("Notas de Fondo: \(perfume.notas.suffix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    .padding(.horizontal)

                    // Recomendaciones de Uso
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recomendaciones de Uso")
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))

                        Text("Momento del día: Día y noche")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        Text("Estación: Todo el año")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                        
                        Text("Duración: 4-6 horas")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    .padding(.horizontal)

                    // Productos Relacionados
                    if !relatedPerfumes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Productos Relacionados")
                                .font(.headline)
                                .foregroundColor(Color("textoPrincipal"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(relatedPerfumes) { relatedPerfume in
                                        VStack {
                                            Image(relatedPerfume.image_name)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)

                                            Text(relatedPerfume.nombre)
                                                .font(.caption)
                                                .foregroundColor(Color("textoPrincipal"))
                                                .lineLimit(1)
                                        }
                                        .frame(width: 100)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Ficha")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color("textoPrincipal"))
                },
                trailing: HStack(spacing: 16) {
                    // Botón de Favoritos
                    Button(action: {
                        if favoritesManager.isFavorite(perfume) {
                            showRemoveFromFavoritesAlert = true
                        } else {
                            favoritesManager.addToFavorites(perfume)
                        }
                    }) {
                        Image(systemName: favoritesManager.isFavorite(perfume) ? "star.fill" : "star")
                            .foregroundColor(favoritesManager.isFavorite(perfume) ? .yellow : .gray)
                    }
                    .alert(isPresented: $showRemoveFromFavoritesAlert) {
                        Alert(
                            title: Text("Eliminar de Favoritos"),
                            message: Text("¿Estás seguro de que deseas eliminar este perfume de tus favoritos?"),
                            primaryButton: .destructive(Text("Eliminar")) {
                                favoritesManager.removeFromFavorites(perfume)
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    // Botón de Lista de Deseos
                    Button(action: {
                        if wishlistManager.isInWishlist(perfume) {
                            showRemoveFromWishlistAlert = true
                        } else {
                            wishlistManager.addToWishlist(perfume)
                        }
                    }) {
                        Image(systemName: wishlistManager.isInWishlist(perfume) ? "cart.fill" : "cart")
                            .foregroundColor(wishlistManager.isInWishlist(perfume) ? .blue : .gray)
                    }
                    .alert(isPresented: $showRemoveFromWishlistAlert) {
                        Alert(
                            title: Text("Eliminar de Lista de Deseos"),
                            message: Text("¿Estás seguro de que deseas eliminar este perfume de tu lista de deseos?"),
                            primaryButton: .destructive(Text("Eliminar")) {
                                wishlistManager.removeFromWishlist(perfume)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            )
        }
    }
}
