import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var userViewModel: UserViewModel // ✅ Necesario para isLoading
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel


    var body: some View {
        Group {
            // ✅ FIX: Pantalla completa de loading que REEMPLAZA el TabView
            if userViewModel.isLoading {
                LoadingScreen {
                    // Retry callback
                    print("🔄 [MainTabView] Retry button tapped")
                    userViewModel.retryLoadData()
                }
            } else {
                TabView(selection: $selectedTab) {
                    HomeTabView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Inicio")
                        }
                        .tag(0)

                    ExploreTabView()
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Explorar")
                        }
                        .tag(1)

                    TestOlfativoTabView()
                        .tabItem {
                            Image(systemName: "drop.fill")
                            Text("Test")
                        }
                        .tag(2)

                    FragranceLibraryTabView()
                        .tabItem {
                            Image(systemName: "books.vertical.fill")
                            Text("Mi Colección")
                        }
                        .tag(3)

                    SettingsViewNew()
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Ajustes")
                        }
                        .tag(4)
                }
                .accentColor(Color("Gold"))
                .onAppear {
                     let tabBarAppearance = UITabBarAppearance()
                     tabBarAppearance.configureWithTransparentBackground()
                     tabBarAppearance.backgroundColor = .clear
                     UITabBar.appearance().standardAppearance = tabBarAppearance
                     UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
            }
        }
        .onAppear {
            PerformanceLogger.logViewAppear("MainTabView")

            // ✅ PASO 5: MainTabView inicia la carga de datos del usuario
            if let userId = authViewModel.currentUser?.id {
                print("🚀 [MainTabView] User authenticated, starting data load...")
                Task {
                    // Load user data (uses smart loading strategy)
                    await userViewModel.loadInitialUserData(userId: userId)

                    // ✅ CRITICAL: Pre-load perfumes for LibraryTab (wishlist + tried)
                    // This prevents race condition where WishListRowView renders before perfumes are loaded
                    let wishlistKeys = userViewModel.wishlistPerfumes.map { $0.perfumeId }
                    let triedKeys = userViewModel.triedPerfumes.map { $0.perfumeId }
                    let allLibraryKeys = Array(Set(wishlistKeys + triedKeys))

                    if !allLibraryKeys.isEmpty {
                        print("📥 [MainTabView] Pre-loading \(allLibraryKeys.count) library perfumes...")
                        await perfumeViewModel.loadPerfumesByKeys(allLibraryKeys)
                        print("✅ [MainTabView] Library perfumes loaded: \(perfumeViewModel.perfumeIndex.count) in index")
                    }
                }
            } else {
                print("⚠️ [MainTabView] No user found, skipping data load")
            }

            // ⚡ Load only essential data at launch
            // Other data loads lazily when tabs are accessed
            loadEssentialData()
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("MainTabView")
        }
        .onChange(of: selectedTab) { newTab in
            PerformanceLogger.logViewModelLoad("MainTabView", action: "tabChanged(to: \(newTab))")
        }
    }

    // MARK: - Essential Data Loading

    /// Carga datos esenciales para que TODOS los tabs funcionen
    /// Se llama en paralelo con UserViewModel.loadEssentialData()
    private func loadEssentialData() {
        print("🚀 [MainTabView] Loading essential data for all tabs...")

        // Metadata (para HomeTab recomendaciones + ExploreTab)
        Task(priority: .userInitiated) { [weak perfumeViewModel] in
            do {
                await perfumeViewModel?.loadMetadataIndex()
                print("✅ [MainTabView] Essential: Metadata loaded")
            } catch {
                print("❌ [MainTabView] Essential: Metadata failed - \(error.localizedDescription)")
            }
        }

        // Brands (para ExploreTab - mostrar nombres de marcas)
        Task(priority: .userInitiated) { [weak brandViewModel] in
            do {
                await brandViewModel?.loadInitialData()
                print("✅ [MainTabView] Essential: Brands loaded")
            } catch {
                print("❌ [MainTabView] Essential: Brands failed - \(error.localizedDescription)")
            }
        }

        // Families (para ExploreTab filtros)
        Task(priority: .userInitiated) { [weak familiaOlfativaViewModel] in
            do {
                await familiaOlfativaViewModel?.loadInitialData()
                print("✅ [MainTabView] Essential: Families loaded")
            } catch {
                print("❌ [MainTabView] Essential: Families failed - \(error.localizedDescription)")
            }
        }

        // Questions (para TestTab - solo onboarding de perfil)
        Task(priority: .userInitiated) { [weak testViewModel] in
            do {
                await testViewModel?.loadInitialData()
                print("✅ [MainTabView] Essential: Questions loaded")
            } catch {
                print("❌ [MainTabView] Essential: Questions failed - \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Loading Screen
/// ✅ Pantalla completa de loading que REEMPLAZA el TabView durante la carga inicial
/// Incluye timeout de 30s y botón de retry
struct LoadingScreen: View {
    @State private var hasTimedOut = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    let onRetry: (() -> Void)?

    init(onRetry: (() -> Void)? = nil) {
        self.onRetry = onRetry
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .ignoresSafeArea()

            if hasTimedOut {
                // Mostrar error después de timeout
                timeoutView
            } else {
                // Mostrar loading normal
                loadingView
            }
        }
        .onAppear {
            startTimeoutTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            // Animación de aroma expandiéndose
            PerfumeFragranceAnimation()
                .frame(width: 120, height: 120)

            Text("Cargando tus perfumes...")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(Color("textoPrincipal"))

            // Indicador de tiempo (después de 10s)
            if elapsedTime > 10 {
                Text("\(Int(elapsedTime))s...")
                    .font(.caption)
                    .foregroundColor(Color("textoSecundario"))
            }
        }
    }

    private var timeoutView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))

            VStack(spacing: 12) {
                Text("No se pudo conectar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("textoPrincipal"))

                Text("Verifica tu conexión a internet\ne inténtalo de nuevo")
                    .font(.body)
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.center)
            }

            if let onRetry = onRetry {
                Button {
                    hasTimedOut = false
                    elapsedTime = 0
                    startTimeoutTimer()
                    onRetry()
                } label: {
                    Text("Reintentar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color("Gold"))
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }

    private func startTimeoutTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1

            // Timeout después de 30 segundos
            if elapsedTime >= 30 {
                timer?.invalidate()
                timer = nil
                hasTimedOut = true
                print("⏱️ [LoadingScreen] Timeout reached (30s)")
            }
        }
    }
}

// MARK: - Perfume Fragrance Animation
/// Animación elegante de botella de perfume con partículas flotantes
struct PerfumeFragranceAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Partículas flotando (aroma dispersándose)
            ForEach(0..<12) { index in
                FloatingParticle(
                    delay: Double(index) * 0.15,
                    xOffset: CGFloat.random(in: -40...40),
                    duration: Double.random(in: 2.5...4.0)
                )
                .position(
                    x: 60 + CGFloat.random(in: -30...30),
                    y: 80 + CGFloat(index) * 3
                )
            }

            // Botella de perfume estilizada
            VStack(spacing: 4) {
                // Tapa
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color("Gold"), Color("Gold").opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 20, height: 12)

                // Cuello
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color("Gold").opacity(0.3))
                    .frame(width: 12, height: 8)

                // Cuerpo de la botella
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("Gold").opacity(0.4),
                                Color("Gold").opacity(0.2),
                                Color("Gold").opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 55)
                    .overlay(
                        // Brillo en la botella
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isAnimating ? 0.4 : 0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: 20, height: 55)
                            .offset(x: -8)
                    )
            }
            .offset(y: 10)
        }
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Floating Particle
/// Partícula individual que flota hacia arriba simulando el aroma
struct FloatingParticle: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    let delay: Double
    let xOffset: CGFloat
    let duration: Double

    var body: some View {
        Circle()
            .fill(Color("Gold"))
            .frame(width: CGFloat.random(in: 3...6), height: CGFloat.random(in: 3...6))
            .offset(x: xOffset, y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation
                        .easeOut(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    offset = -100
                    opacity = 0
                }

                withAnimation(
                    Animation
                        .easeIn(duration: 0.5)
                        .delay(delay)
                ) {
                    opacity = 0.6
                }
            }
    }
}
