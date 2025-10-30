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

                // ✅ PATRÓN DE 3 ESTADOS: Loading → Content → Empty State
                VStack(spacing: 0) {
                    if olfactiveProfileViewModel.isLoading {
                        // Estado 1: Loading - Mostrar skeleton o nada (evita flash)
                        profilesLoadingSkeleton
                    } else if !olfactiveProfileViewModel.profiles.isEmpty {
                        // Estado 2: Content - Mostrar perfiles
                        GreetingSection(userName: authViewModel.currentUser?.displayName ?? "Usuario")
                            .padding(.horizontal, 25)
                            .padding(.top, 16)
                        profileTabView
                    } else {
                        // Estado 3: Empty State - Realmente no hay perfiles
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
                // Obtener brand y profile, pero no bloquear si no existen
                let brand = brandViewModel.getBrand(byKey: perfume.brand)
                let profile = olfactiveProfileViewModel.profiles.indices.contains(selectedTabIndex) ? olfactiveProfileViewModel.profiles[selectedTabIndex] : olfactiveProfileViewModel.profiles.first

                PerfumeDetailView(
                    perfume: perfume,
                    brand: brand, // nil si no se encuentra
                    profile: profile // nil si no hay profiles
                )
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
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }

    // ✅ SKELETON LOADER: Evita flash de empty state durante carga de caché
    private var profilesLoadingSkeleton: some View {
        VStack(spacing: 16) {
            // Skeleton para greeting
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 180, height: 24)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 140, height: 20)
            }
            .padding(.horizontal, 25)
            .padding(.top, 16)

            // Skeleton para profile card
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .frame(height: 500)
                .padding(.horizontal, 25)
                .overlay(
                    VStack(spacing: 20) {
                        // Icon placeholder
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 80, height: 80)

                        // Title placeholders
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 200, height: 28)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 250, height: 20)
                        }

                        Spacer()

                        // Button placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 50)
                            .padding(.horizontal, 30)
                    }
                    .padding(.vertical, 40)
                )

            Spacer()
        }
        .transition(.opacity)
    }
}
