import SwiftUI
import Combine
import Foundation

struct FragranceLibraryTabView: View {
    @State private var isAddingPerfume = false
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var brandViewModel : BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @State private var selectedPerfume: Perfume? = nil
    @State private var perfumesToDisplay: [TriedPerfumeRecord] = []
    @State private var wishlistPerfumes: [WishlistItem] = []

    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    headerView

                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            TriedPerfumesSection(
                                title: "Tus Perfumes Probados",
                                triedPerfumes: $perfumesToDisplay,
                                maxDisplayCount: 4,
                                addAction: { isAddingPerfume = true },
                                seeMoreDestination: TriedPerfumesListView(
                                    triedPerfumesInput: perfumesToDisplay,
                                    familyViewModel: familyViewModel
                                ),
                                userViewModel: userViewModel
                            )

                            Divider()

                            WishListSection(
                                title: "Tu Lista de Deseos",
                                perfumes: wishlistPerfumes,
                                message: "Busca un perfume y pulsa el botón de carrito para añadirlo a tu lista de deseos.",
                                maxDisplayCount: 3,
                                seeMoreDestination: WishlistListView(
                                    wishlistItemsInput: $wishlistPerfumes,
                                    familyViewModel: familyViewModel
                                )
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
                    .onDisappear {
                        Task {
                            await brandViewModel.loadInitialData()
                            await userViewModel.loadTriedPerfumes()
                            await userViewModel.loadWishlist()
                            perfumesToDisplay = userViewModel.triedPerfumes
                            wishlistPerfumes = userViewModel.wishlistPerfumes
                        }
                    }
            }
        }
        .environmentObject(userViewModel)
        .environmentObject(brandViewModel)
        .environmentObject(familyViewModel)
        .onAppear {
            PerformanceLogger.logViewAppear("FragranceLibraryTabView")
            Task {
                await brandViewModel.loadInitialData()
                await userViewModel.loadTriedPerfumes()
                await userViewModel.loadWishlist()
                perfumesToDisplay = userViewModel.triedPerfumes
                wishlistPerfumes = userViewModel.wishlistPerfumes
            }
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("FragranceLibraryTabView")
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
