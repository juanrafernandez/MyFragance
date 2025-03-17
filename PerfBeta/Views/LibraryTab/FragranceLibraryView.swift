import SwiftUI
import Combine
import Foundation

struct FragranceLibraryView: View {
    @State private var isAddingPerfume = false
    @StateObject var userViewModel = UserViewModel()
    @StateObject var brandViewModel = BrandViewModel() // Inject BrandViewModel
    @State private var selectedPerfume: Perfume? = nil
    @State private var perfumesToDisplay: [TriedPerfumeRecord] = []
    @State private var wishlistPerfumes: [WishlistItem] = []
    
    let userId = "testUserId" // IMPORTANT: Replace with your actual user ID
    // MARK: - Selected Gradient Preset - AppStorage
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan // Default preset

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    headerView

                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            // Tus Perfumes Probados
                            TriedPerfumesSection(
                                title: "Tus Perfumes Probados",
                                triedPerfumes: $perfumesToDisplay,
                                maxDisplayCount: 5,
                                addAction: { isAddingPerfume = true },
                                seeMoreDestination: TriedPerfumesListView(userId: "testUserId", triedPerfumes: perfumesToDisplay),
                                userViewModel: userViewModel
                            )

                            Divider()

                            // Tu Lista de Deseos
                            WishListSection(
                                title: "Tu Lista de Deseos",
                                perfumes: wishlistPerfumes,
                                message: "Busca un perfume y pulsa el botón de carrito para añadirlo a tu lista de deseos.",
                                maxDisplayCount: 3,
                                seeMoreDestination: WishlistListView(perfumes: $wishlistPerfumes)
                            )
                        }
                        .padding(.horizontal,25)
                    }
                }
                .background(Color.clear)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isAddingPerfume) {
                AddPerfumeInitialStepsView(isAddingPerfume: $isAddingPerfume) // MODIFIED: Present AddPerfumeInitialStepsView
                    .environmentObject(userViewModel)
                    .environmentObject(brandViewModel) // Make BrandViewModel available in the environment
                    .onDisappear {
                        Task {
                            await brandViewModel.loadInitialData() // Load Brands FIRST
                            await userViewModel.loadTriedPerfumes(userId: userId)
                            await userViewModel.loadWishlist(userId: userId)
                            //perfumesToDisplay = await convertTriedPerfumeRecordsToPerfumes(userViewModel.triedPerfumesRecords)
                            perfumesToDisplay = userViewModel.triedPerfumes
                            wishlistPerfumes = userViewModel.wishlistPerfumes
                        }
                    }
            }
        }
        .environmentObject(userViewModel)
        .environmentObject(brandViewModel) // Make BrandViewModel available in the environment if needed deeper down
        .onAppear {
            Task {
                await brandViewModel.loadInitialData() // Load Brands FIRST
                await userViewModel.loadTriedPerfumes(userId: userId)
                await userViewModel.loadWishlist(userId: userId)
                //perfumesToDisplay = await convertTriedPerfumeRecordsToPerfumes(userViewModel.triedPerfumesRecords)
                perfumesToDisplay = userViewModel.triedPerfumes
                wishlistPerfumes = userViewModel.wishlistPerfumes
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Mi Colección".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
            Spacer()
        }
        .padding(.leading, 25)
        .padding(.top, 16)
    }
}

// MARK: - TriedPerfumeRowView  - MOVER ESTA DEFINICIÓN AQUÍ
struct TriedPerfumeRowView: View {
    let triedPerfume: TriedPerfumeRecord
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var showingDetailView = false
    @State private var detailedPerfume: Perfume? = nil
    @State private var detailedBrand: Brand? = nil
    
    var body: some View {
        Button {
            showingDetailView = true
        } label: {
            HStack(spacing: 15) {
                Image(detailedPerfume?.imageURL ?? "placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(detailedPerfume?.name ?? "Nombre desconocido")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("textoPrincipal"))

                    Text(detailedBrand?.name ?? "Marca desconocida")
                        .font(.system(size: 12))
                        .foregroundColor(Color("textoSecundario"))
                }

                Spacer()

                // Display Rating
                if let rating = triedPerfume.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 5)
            .background(Color.clear)
            .task {
                await loadTriedPerfumeAndBrand()
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetailView) {
            if let perfume = detailedPerfume {
                PerfumeLibraryDetailView(perfume: perfume, triedPerfume: triedPerfume)
            } else {
                EmptyView()
            }
        }
    }
    
    private func loadTriedPerfumeAndBrand() async {
        do {
            // Fetch Perfume
            if let perfume = try await perfumeViewModel.getPerfume(byKey: triedPerfume.perfumeKey) {
                detailedPerfume = perfume
            }
            
            // Fetch Brand
            if let brand = brandViewModel.getBrand(byKey: triedPerfume.brandId) {
                detailedBrand = brand
            }
        } catch {
            print("Error loading perfume or brand: \(error)")
        }
    }
}

// MARK: - Tried Perfumes Section (CORREGIDO)
struct TriedPerfumesSection<Destination: View>: View {
    let title: String
    @Binding var triedPerfumes: [TriedPerfumeRecord]
    let maxDisplayCount: Int
    let addAction: () -> Void
    let seeMoreDestination: Destination
    @ObservedObject var userViewModel: UserViewModel // Receive UserViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !triedPerfumes.isEmpty {
                    NavigationLink(destination: seeMoreDestination) {
                        Text("Ver más")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("textoPrincipal"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("champan").opacity(0.1))
                            )
                    }
                }
            }
            .padding(.bottom, 5)
            
            if triedPerfumes.isEmpty {
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
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(triedPerfumes.prefix(maxDisplayCount), id: \.id) { triedPerfume in
                        TriedPerfumeRowView(triedPerfume: triedPerfume)
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
                .padding(.top, 10)
            }
        }
    }
}


// MARK: - Compact Section con mensaje para listas vacías (CORREGIDO)
struct WishListSection<Destination: View>: View {
    let title: String
    let perfumes: [WishlistItem]
    let message: String
    let maxDisplayCount: Int
    let seeMoreDestination: Destination

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !perfumes.isEmpty {
                    NavigationLink(destination: seeMoreDestination) {
                        Text("Ver más")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("textoPrincipal"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("champan").opacity(0.1))
                            )
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
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(perfumes.prefix(maxDisplayCount), id: \.id) { perfume in
                        WishListRowView(perfume: perfume)
                    }
                }
            }
        }
    }
}

struct WishListRowView: View {
    let perfume: WishlistItem
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var showingDetailView = false
    @State private var detailedPerfume: Perfume? = nil
    @State private var detailedBrand: Brand? = nil
    
    var body: some View {
        Button {
            showingDetailView = true
        } label: {
            HStack(spacing: 15) {
                Image(perfume.imageURL ?? "placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    if let detailedPerfume = detailedPerfume {
                        Text(detailedPerfume.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    } else {
                        Text(perfume.perfumeKey)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                    
                    if let brand = detailedBrand {
                        Text(brand.name)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    } else {
                        Text(perfume.brandKey)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                
                Spacer()

                // Display Rating if available
                if perfume.rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", perfume.rating))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 5)
            .background(Color.clear)
            .task {
                await loadPerfumeAndBrand()
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetailView) {
            if let perfume = detailedPerfume, let brand = detailedBrand {
                PerfumeDetailView(
                    perfume: perfume,
                    relatedPerfumes: perfumeViewModel.perfumes.filter { $0.id != perfume.id },
                    brand: brand
                )
            } else {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity) // Asegura que ocupe el ancho disponible
    }
    
    private func loadPerfumeAndBrand() async {
        do {
            // Fetch Perfume
            if let perfume = try await perfumeViewModel.getPerfume(byKey: perfume.perfumeKey) {
                detailedPerfume = perfume
            }
            
            // Fetch Brand
            if let brand = brandViewModel.getBrand(byKey: perfume.brandKey) {
                detailedBrand = brand
            }
        } catch {
            print("Error loading perfume or brand: \(error)")
        }
    }
}


struct WishlistView: View {
    var body: some View {
        Text("Lista completa de deseos")
    }
}
