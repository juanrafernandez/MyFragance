import SwiftUI
import Combine
import Foundation

struct FragranceLibraryTabView: View {
    @State private var isAddingPerfume = false
    @StateObject var userViewModel = UserViewModel()
    @StateObject var brandViewModel = BrandViewModel() // Inject BrandViewModel
    @State private var selectedPerfume: Perfume? = nil
    @State private var perfumesToDisplay: [TriedPerfumeRecord] = []
    @State private var wishlistPerfumes: [WishlistItem] = []
    
    let userId = "testUserId"
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
                                maxDisplayCount: 4,
                                addAction: { isAddingPerfume = true },
                                seeMoreDestination: TriedPerfumesListView(userId: "testUserId", triedPerfumesInput: perfumesToDisplay),
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
                AddPerfumeInitialStepsView(isAddingPerfume: $isAddingPerfume)
                    .environmentObject(userViewModel)
                    .environmentObject(brandViewModel)
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
