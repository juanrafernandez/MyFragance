import SwiftUI

// MARK: - Animated Splash View
/// Pantalla de splash animada - Continuidad con LaunchScreen
/// Secuencia:
/// 1. Logo fijo (igual que LaunchScreen)
/// 2. Letras "Baura" aparecen una por una
/// 3. Si la carga tarda, el logo hace heartbeat
struct AnimatedSplashView: View {
    // MARK: - Configuration
    private let appName = "Baura"

    // Timing
    private let letterStartDelay: Double = 0.3      // Pausa antes de que aparezcan las letras
    private let letterDelay: Double = 0.12          // Delay entre cada letra
    private let minimumDisplayTime: Double = 2.0   // Tiempo mínimo de splash

    // Sizes (exactamente igual que LaunchScreen)
    private let logoSize: CGFloat = 120

    // Colores del LaunchScreen
    private let launchScreenBackground = Color(red: 0.949, green: 0.933, blue: 0.878)

    // MARK: - State
    @State private var letterOpacities: [Double]
    @State private var letterOffsets: [CGFloat]
    @State private var logoOpacity: Double = 1.0
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var isHeartbeating = false
    @State private var canDismiss = false
    @State private var hasDismissed = false
    @State private var dataLoadedInternal = false
    @State private var lettersFinished = false

    // MARK: - Props
    let isDataLoaded: Bool
    let onAnimationComplete: () -> Void

    // MARK: - Init
    init(isDataLoaded: Bool = false, onAnimationComplete: @escaping () -> Void) {
        self.isDataLoaded = isDataLoaded
        self.onAnimationComplete = onAnimationComplete
        _letterOpacities = State(initialValue: Array(repeating: 0.0, count: "Baura".count))
        _letterOffsets = State(initialValue: Array(repeating: 12.0, count: "Baura".count))
        _dataLoadedInternal = State(initialValue: isDataLoaded)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Background (exactamente igual que LaunchScreen)
            launchScreenBackground
                .ignoresSafeArea()

            // MARK: - Content
            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo (fijo, sin animación inicial)
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: logoSize, height: logoSize)
                    .scaleEffect(heartbeatScale)
                    .opacity(logoOpacity)

                // Spacing entre logo y texto
                Spacer().frame(height: 28)

                // MARK: - App Name con animación letra por letra
                HStack(spacing: 3) {
                    ForEach(Array(appName.enumerated()), id: \.offset) { index, letter in
                        Text(String(letter))
                            .font(.custom("Georgia", size: 38))
                            .fontWeight(.light)
                            .foregroundColor(AppColor.accentGold)
                            .opacity(letterOpacities[index])
                            .offset(y: letterOffsets[index])
                    }
                }

                Spacer()

                // MARK: - Loading Indicator (solo si está esperando y heartbeat activo)
                if isHeartbeating && !dataLoadedInternal {
                    LoadingDotsView()
                        .padding(.bottom, 60)
                        .transition(.opacity.animation(.easeIn(duration: 0.3)))
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isDataLoaded) { _, loaded in
            dataLoadedInternal = loaded
            checkDismiss()
        }
        .onChange(of: canDismiss) { _, _ in
            checkDismiss()
        }
    }

    // MARK: - Animation Sequence
    private func startAnimations() {
        #if DEBUG
        print("🎬 [AnimatedSplash] Starting animation sequence...")
        #endif

        // FASE 1: Logo ya está fijo (continuidad perfecta con LaunchScreen)

        // FASE 2: Letras aparecen una por una
        for index in 0..<appName.count {
            let delay = letterStartDelay + Double(index) * letterDelay

            withAnimation(
                .spring(response: 0.4, dampingFraction: 0.75)
                .delay(delay)
            ) {
                letterOpacities[index] = 1.0
                letterOffsets[index] = 0
            }
        }

        // Calcular cuándo terminan las letras
        let lettersEndTime = letterStartDelay + Double(appName.count) * letterDelay + 0.4

        DispatchQueue.main.asyncAfter(deadline: .now() + lettersEndTime) {
            lettersFinished = true

            #if DEBUG
            print("✅ [AnimatedSplash] Letters animation finished")
            #endif

            // FASE 3: Si la carga no ha terminado, iniciar heartbeat
            if !dataLoadedInternal {
                startHeartbeat()
            }
        }

        // Marcar tiempo mínimo de display
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayTime) {
            #if DEBUG
            print("⏱️ [AnimatedSplash] Minimum display time reached")
            #endif
            canDismiss = true
            checkDismiss()
        }
    }

    // MARK: - Heartbeat Animation
    private func startHeartbeat() {
        guard !hasDismissed && !isHeartbeating else { return }

        isHeartbeating = true

        #if DEBUG
        print("💓 [AnimatedSplash] Starting heartbeat...")
        #endif

        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            heartbeatScale = 1.04
        }
    }

    private func stopHeartbeat() {
        guard isHeartbeating else { return }

        isHeartbeating = false
        withAnimation(.easeOut(duration: 0.15)) {
            heartbeatScale = 1.0
        }
    }

    // MARK: - Check & Dismiss
    private func checkDismiss() {
        if canDismiss && dataLoadedInternal && !hasDismissed {
            dismissSplash()
        }
    }

    private func dismissSplash() {
        guard !hasDismissed else { return }
        hasDismissed = true

        #if DEBUG
        print("🚀 [AnimatedSplash] Dismissing splash...")
        #endif

        stopHeartbeat()

        // Transición de salida
        withAnimation(.easeOut(duration: 0.25)) {
            logoOpacity = 0
            for index in 0..<appName.count {
                letterOpacities[index] = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAnimationComplete()
        }
    }
}

// MARK: - Loading Dots View
/// Indicador de carga con tres puntos animados
struct LoadingDotsView: View {
    @State private var animatingDots = [false, false, false]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppColor.brandAccent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDots[index] ? 1.0 : 0.5)
                    .opacity(animatingDots[index] ? 1.0 : 0.4)
            }
        }
        .onAppear {
            for index in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.15)
                ) {
                    animatingDots[index] = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Splash - Carga Rápida") {
    AnimatedSplashView(isDataLoaded: true) {
        print("Splash dismissed")
    }
}

#Preview("Splash - Carga Lenta") {
    AnimatedSplashView(isDataLoaded: false) {
        print("Splash dismissed")
    }
}
