import SwiftUI

// MARK: - Animated Splash View
/// Pantalla de splash animada estilo Netflix/Premium
/// - LaunchScreen muestra el logo estático
/// - Esta vista muestra el AppIcon arriba y anima "Baura" apareciendo letra por letra debajo
/// - Si la carga tarda, el AppIcon "late" sutilmente (heartbeat)
struct AnimatedSplashView: View {
    // MARK: - Configuration
    private let appName = "Baura"

    // Timing
    private let letterAnimationDuration: Double = 0.18
    private let letterDelay: Double = 0.14
    private let minimumDisplayTime: Double = 1.8  // Tiempo mínimo antes de poder cerrar
    private let heartbeatStartDelay: Double = 2.5 // Cuándo empieza heartbeat si sigue cargando

    // MARK: - State
    @State private var letterOpacities: [Double]
    @State private var logoOpacity: Double = 1.0
    @State private var isHeartbeating = false
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var canDismiss = false
    @State private var hasDismissed = false
    @State private var dataLoadedInternal = false

    // MARK: - Props (from parent - reactive)
    let isDataLoaded: Bool
    let onAnimationComplete: () -> Void

    // MARK: - Init
    init(isDataLoaded: Bool = false, onAnimationComplete: @escaping () -> Void) {
        self.isDataLoaded = isDataLoaded
        self.onAnimationComplete = onAnimationComplete
        // Inicializar opacidades de letras a 0
        _letterOpacities = State(initialValue: Array(repeating: 0.0, count: "Baura".count))
        _dataLoadedInternal = State(initialValue: isDataLoaded)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Fondo champán (igual que LaunchScreen)
            Color(red: 0.949, green: 0.933, blue: 0.878)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // MARK: - App Icon (con heartbeat si carga tarda)
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .scaleEffect(heartbeatScale)
                    .opacity(logoOpacity)

                // MARK: - App Name (letras fade in secuencial)
                HStack(spacing: 0) {
                    ForEach(Array(appName.enumerated()), id: \.offset) { index, letter in
                        Text(String(letter))
                            .font(.custom("Georgia", size: 38))
                            .foregroundColor(AppColor.accentGold)
                            .opacity(letterOpacities[index])
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isDataLoaded) { _, loaded in
            #if DEBUG
            print("🔄 [AnimatedSplash] isDataLoaded (prop) changed to: \(loaded)")
            #endif
            // Sincronizar con state interno
            dataLoadedInternal = loaded
        }
        .onChange(of: dataLoadedInternal) { _, loaded in
            #if DEBUG
            print("🔄 [AnimatedSplash] dataLoadedInternal changed to: \(loaded), canDismiss: \(canDismiss)")
            #endif
            if loaded && canDismiss {
                checkDismissConditions()
            }
        }
        .onChange(of: canDismiss) { _, canDismissNow in
            #if DEBUG
            print("🔄 [AnimatedSplash] canDismiss changed to: \(canDismissNow), dataLoadedInternal: \(dataLoadedInternal)")
            #endif
            if canDismissNow && dataLoadedInternal {
                checkDismissConditions()
            }
        }
    }

    // MARK: - Animation Logic

    /// Inicia todas las animaciones
    private func startAnimations() {
        #if DEBUG
        print("🎬 [AnimatedSplash] Starting animations...")
        #endif

        // Animar cada letra con delay secuencial
        for index in 0..<appName.count {
            let delay = Double(index) * letterDelay

            withAnimation(
                .easeOut(duration: letterAnimationDuration)
                .delay(delay)
            ) {
                letterOpacities[index] = 1.0
            }
        }

        // Calcular cuándo terminan todas las letras
        let totalLetterAnimationTime = Double(appName.count - 1) * letterDelay + letterAnimationDuration

        // Después de que las letras aparezcan, activar posibilidad de dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + max(totalLetterAnimationTime, minimumDisplayTime)) {
            #if DEBUG
            print("✅ [AnimatedSplash] Animations complete, can dismiss now")
            #endif
            canDismiss = true
            checkDismissConditions()
        }

        // Iniciar heartbeat si la carga tarda
        DispatchQueue.main.asyncAfter(deadline: .now() + heartbeatStartDelay) {
            if !hasDismissed && !dataLoadedInternal {
                startHeartbeat()
            }
        }
    }

    /// Inicia la animación de heartbeat sutil en el logo
    private func startHeartbeat() {
        guard !hasDismissed else { return }

        isHeartbeating = true
        #if DEBUG
        print("💓 [AnimatedSplash] Starting heartbeat on logo...")
        #endif

        // Heartbeat loop - escala sutil
        withAnimation(
            .easeInOut(duration: 0.9)
            .repeatForever(autoreverses: true)
        ) {
            heartbeatScale = 1.04  // 4% más grande
        }
    }

    /// Detiene el heartbeat
    private func stopHeartbeat() {
        guard isHeartbeating else { return }

        #if DEBUG
        print("💓 [AnimatedSplash] Stopping heartbeat")
        #endif

        isHeartbeating = false
        withAnimation(.easeOut(duration: 0.2)) {
            heartbeatScale = 1.0
        }
    }

    /// Verifica si se cumplen las condiciones para cerrar el splash
    private func checkDismissConditions() {
        guard !hasDismissed else { return }

        // Condiciones para cerrar:
        // 1. Tiempo mínimo transcurrido (canDismiss)
        // 2. Datos cargados (dataLoadedInternal - synced from prop)

        #if DEBUG
        print("🔍 [AnimatedSplash] checkDismissConditions - canDismiss: \(canDismiss), dataLoadedInternal: \(dataLoadedInternal)")
        #endif

        guard canDismiss && dataLoadedInternal else {
            #if DEBUG
            if !canDismiss {
                print("⏳ [AnimatedSplash] Waiting for minimum display time...")
            } else if !dataLoadedInternal {
                print("⏳ [AnimatedSplash] Waiting for data to load...")
            }
            #endif
            return
        }

        #if DEBUG
        print("🚀 [AnimatedSplash] All conditions met - dismissing splash")
        #endif

        hasDismissed = true
        stopHeartbeat()

        // Transición suave
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onAnimationComplete()
        }
    }
}

// MARK: - Preview
#Preview("Splash - Normal") {
    AnimatedSplashView(isDataLoaded: true) {
        print("Splash dismissed")
    }
}

#Preview("Splash - Carga Lenta") {
    AnimatedSplashView(isDataLoaded: false) {
        print("Splash dismissed")
    }
}
