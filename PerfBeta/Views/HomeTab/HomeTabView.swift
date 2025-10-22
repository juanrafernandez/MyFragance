import SwiftUI
import Combine

struct HomeTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Necesario para el nombre

    @State private var selectedTabIndex = 0
    @State private var selectedPerfume: Perfume? = nil
    @State private var isPresentingTestView = false
    // ✅ ELIMINADO: Sistema de temas personalizable

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.2))
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    if !olfactiveProfileViewModel.profiles.isEmpty {
                        GreetingSection(userName: authViewModel.currentUser?.name ?? "Usuario")
                            .padding(.horizontal, 25)
                            .padding(.top, 16)
                        profileTabView
                    } else {
                        introductionSection
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                PerformanceLogger.logViewAppear("HomeTabView")
            }
            .onDisappear {
                PerformanceLogger.logViewDisappear("HomeTabView")
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                if let brand = brandViewModel.getBrand(byKey: perfume.brand),
                   let profile = olfactiveProfileViewModel.profiles.indices.contains(selectedTabIndex) ? olfactiveProfileViewModel.profiles[selectedTabIndex] : olfactiveProfileViewModel.profiles.first {
                    PerfumeDetailView(
                        perfume: perfume,
                        brand: brand,
                        profile: profile
                    )
                } else {
                    Text("Error al cargar detalles")
                        .padding()
                }
            }
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
            .environmentObject(familiaOlfativaViewModel)
            .environmentObject(olfactiveProfileViewModel)
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
        }
    }

    private var introductionSection: some View {
        VStack(spacing: 24) {
            Image("welcome")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)
                .cornerRadius(12)
                .padding(.horizontal, 24)

            Text("Bienvenido a tu Perfumería Personal")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Text("""
            Aquí podrás descubrir recomendaciones de fragancias personalizadas según tu perfil olfativo.
            Crea tu primer perfil para recibir sugerencias y explorar perfumes ideales para ti.
            """)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: {
                isPresentingTestView = true
            }) {
                Text("Crear mi Perfil Olfativo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("champan"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .padding(.top, 50)
    }

    private var profileTabView: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(Array(olfactiveProfileViewModel.profiles.enumerated()), id: \.element.id) { index, profile in
                ProfileCard(profile: profile, perfumeViewModel: perfumeViewModel, selectedPerfume: $selectedPerfume)
                    .tag(index)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 30)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}
