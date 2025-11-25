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

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Ajustes")
                }
                .tag(4)
        }
        .accentColor(AppColor.brandAccent)
        .onAppear {
            PerformanceLogger.logViewAppear("MainTabView")

            // Configurar apariencia del TabBar
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithTransparentBackground()
            tabBarAppearance.backgroundColor = .clear
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

            #if DEBUG
            print("✅ [MainTabView] Displayed with pre-loaded data")
            #endif
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("MainTabView")
        }
        .onChange(of: selectedTab) {
            PerformanceLogger.logViewModelLoad("MainTabView", action: "tabChanged(to: \(selectedTab))")
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
                .foregroundColor(AppColor.textPrimary)

            // Indicador de tiempo (después de 10s)
            if elapsedTime > 10 {
                Text("\(Int(elapsedTime))s...")
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
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
                    .foregroundColor(AppColor.textPrimary)

                Text("Verifica tu conexión a internet\ne inténtalo de nuevo")
                    .font(.body)
                    .foregroundColor(AppColor.textSecondary)
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
                        .background(AppColor.brandAccent)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .padding(AppSpacing.sectionSpacing)
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
                #if DEBUG
                print("⏱️ [LoadingScreen] Timeout reached (30s)")
                #endif
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
                            colors: [AppColor.brandAccent, AppColor.brandAccent.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 20, height: 12)

                // Cuello
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppColor.brandAccent.opacity(0.3))
                    .frame(width: 12, height: 8)

                // Cuerpo de la botella
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColor.brandAccent.opacity(0.4),
                                AppColor.brandAccent.opacity(0.2),
                                AppColor.brandAccent.opacity(0.3)
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
    @State private var isAnimating = false
    let delay: Double
    let xOffset: CGFloat
    let duration: Double
    let size: CGFloat = CGFloat.random(in: 3...6)

    var body: some View {
        Circle()
            .fill(AppColor.brandAccent)
            .frame(width: size, height: size)
            .offset(x: xOffset, y: isAnimating ? -100 : 0)
            .opacity(isAnimating ? 0 : 0.7)
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}
