import SwiftUI

struct PerfumeDetailView: View {
    @Environment(\.presentationMode) var presentationMode // Para cerrar la interfaz
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var familiaManager: FamiliaOlfativaManager // Inyección del manager

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
                        Image(perfume.imagenURL)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(perfume.nombre)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("textoPrincipal"))

                            Text(perfume.marca)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text(perfume.familia.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    Text(perfume.descripcion)
                        .font(.subheadline)
                        .foregroundColor(Color("textoSecundario"))
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                    
                    // Pirámide Olfativa
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Pirámide Olfativa")
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        
                        Text("Notas Principales: \(perfume.notasPrincipales.prefix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                        
                        Text("Salida: \(perfume.notasSalida.prefix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        Text("Corazón: \(perfume.notasCorazon.dropFirst(2).prefix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        Text("Fondo: \(perfume.notasFondo.suffix(2).joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    .padding(.horizontal)

                    // Recomendaciones de Uso
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensidad y Ocasión")
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))

                        Text("Proyección: \(perfume.proyeccion.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                        
                        Text("Duración: \(perfume.duracion.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                        
                        if let estacion = familiaManager.getEstacionRecomendada(byID: perfume.familia)?.joined(separator: ", ") {
                            Text("Estación: \(estacion)")
                                .font(.subheadline)
                                .foregroundColor(Color("textoSecundario"))
                        } else {
                            Text("Estación: No disponible")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        
                        // Ocasión Recomendada
                        if let ocasion = familiaManager.getOcasion(byID: perfume.familia)?.joined(separator: ", ") {
                            Text("Ocasión: \(ocasion)")
                                .font(.subheadline)
                                .foregroundColor(Color("textoSecundario"))
                        } else {
                            Text("Ocasión: No disponible")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)

                    // Pirámide Olfativa
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Información Adicional")
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))

                        Text("Año: 2920")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        Text("Perfumista: Perfumista Famoso")
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
                                            Image(relatedPerfume.imagenURL)
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
