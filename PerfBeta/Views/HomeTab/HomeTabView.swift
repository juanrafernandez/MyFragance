import SwiftUI
import Combine

// MARK: - HomeTab State

/// Estados posibles de HomeTab durante la carga de perfiles
enum HomeTabLoadingState: Equatable {
    /// Cargando perfiles por primera vez
    case loading

    /// Perfiles cargados (puede haber content o empty state)
    case loaded

    /// Error al cargar perfiles
    case error(String)
}

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
    @State private var homeTabState: HomeTabLoadingState = .loading

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.2))
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                // ✅ ENUM-BASED STATE MACHINE: Clear state transitions
                VStack(spacing: 0) {
                    switch homeTabState {
                    case .loading:
                        // Estado 1: Cargando perfiles - Mostrar skeleton
                        profilesLoadingSkeleton

                    case .loaded:
                        // Estado 2: Perfiles cargados - Mostrar content o empty state
                        if !olfactiveProfileViewModel.profiles.isEmpty {
                            // Content - Mostrar perfiles
                            GreetingSection(userName: authViewModel.currentUser?.displayName ?? "Usuario")
                                .padding(.horizontal, 25)
                                .padding(.top, 16)
                            profileTabView
                        } else {
                            // Empty State - No hay perfiles
                            introductionSection
                        }

                    case .error(let message):
                        // Estado 3: Error al cargar
                        errorView(message: message)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                PerformanceLogger.logViewAppear("HomeTabView")
                updateHomeTabState()
            }
            .onDisappear {
                PerformanceLogger.logViewDisappear("HomeTabView")
            }
            .onChange(of: olfactiveProfileViewModel.hasAttemptedLoad) { _, _ in
                updateHomeTabState()
            }
            .onChange(of: olfactiveProfileViewModel.isLoading) { _, _ in
                updateHomeTabState()
            }
            .onChange(of: olfactiveProfileViewModel.errorMessage) { _, _ in
                updateHomeTabState()
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

    // MARK: - State Management

    /// Actualiza el estado de HomeTab basado en el estado del ViewModel
    private func updateHomeTabState() {
        #if DEBUG
        print("🏠 [HomeTabView] updateHomeTabState called")
        print("   - hasAttemptedLoad: \(olfactiveProfileViewModel.hasAttemptedLoad)")
        print("   - isLoading: \(olfactiveProfileViewModel.isLoading)")
        print("   - profiles count: \(olfactiveProfileViewModel.profiles.count)")
        print("   - errorMessage: \(olfactiveProfileViewModel.errorMessage ?? "nil")")
        #endif

        // Si hay error, mostrar estado de error
        if let errorMessage = olfactiveProfileViewModel.errorMessage, !errorMessage.isEmpty {
            homeTabState = .error(errorMessage)
            #if DEBUG
            print("   → Transition to: .error")
            #endif
            return
        }

        // Si ya intentó cargar (sin importar si está loading o no), mostrar contenido
        if olfactiveProfileViewModel.hasAttemptedLoad {
            homeTabState = .loaded
            #if DEBUG
            print("   → Transition to: .loaded")
            #endif
            return
        }

        // Si no ha intentado cargar aún, mantener loading
        homeTabState = .loading
        #if DEBUG
        print("   → Transition to: .loading")
        #endif
    }

    // MARK: - Views

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

    /// Vista de error cuando falla la carga de perfiles
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color("textoSecundario"))

            Text("Error al cargar perfiles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color("textoPrincipal"))

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 50)
    }
}
