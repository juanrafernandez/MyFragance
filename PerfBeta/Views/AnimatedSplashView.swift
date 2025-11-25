import SwiftUI

/// Animated Splash Screen Premium con Degradado Retrocedente
/// Estrategia: Degradado del header retrocede mientras el logo aparece
/// Inspirado en Airbnb, Headspace, Calm
struct AnimatedSplashView: View {
    // MARK: - Animation States
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.9
    @State private var appNameOpacity: Double = 1.0  // Nombre app visible desde el principio

    // Animación del degradado: de pantalla completa (1.0) a header (0.65)
    @State private var gradientHeight: CGFloat = 1.0  // 100% → 65%
    @State private var gradientOpacity: Double = 1.0

    // MARK: - Completion Handler
    var onAnimationComplete: () -> Void

    // MARK: - Constants
    private let logoAnimationDuration: Double = 1.0
    private let gradientAnimationDuration: Double = 1.2
    private let totalDisplayDuration: Double = 2.5
    private let fadeOutDuration: Double = 0.5

    // MARK: - Gradient Colors (Champán - matching app header)
    private let gradientColors = [
        AppColor.accentGoldDark.opacity(0.5),
        AppColor.brandAccent.opacity(0.5),
        AppColor.brandAccentLight.opacity(0.5),
        .white
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Fondo Blanco Base
                Color.white
                    .ignoresSafeArea()

                // MARK: - Degradado Retrocedente
                // Comienza cubriendo toda la pantalla, retrocede hasta el 65%
                VStack(spacing: 0) {
                    // Gradiente animado
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * gradientHeight)
                    .opacity(gradientOpacity)

                    Spacer()
                }
                .ignoresSafeArea()

                // MARK: - Content
                VStack(spacing: 24) {
                    Spacer()

                    // MARK: - Logo (aparece con fade in mientras degradado retrocede)
                    ZStack {
                        // Logo placeholder (botella estilizada)
                        VStack(spacing: 0) {
                            // Tapa
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColor.accentGold)
                                .frame(width: 30, height: 20)

                            // Cuello
                            Rectangle()
                                .fill(AppColor.accentGold.opacity(0.9))
                                .frame(width: 20, height: 25)

                            // Cuerpo de la botella
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColor.accentGold.opacity(0.95),
                                            AppColor.accentGold.opacity(0.85),
                                            AppColor.accentGold.opacity(0.75)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 90, height: 100)
                                .overlay(
                                    // Brillo sutil
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.35),
                                                    .clear,
                                                    .clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                    }
                    .frame(width: 110, height: 145)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Spacer()

                    // MARK: - App Name (visible desde el principio, fade out al final)
                    VStack(spacing: 8) {
                        Text("PerfBeta")
                            .font(.system(size: 34, weight: .light, design: .serif))
                            .foregroundColor(AppColor.accentGold)

                        Text("Tu perfume perfecto")
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(AppColor.textSecondary)
                            .opacity(0.8)
                    }
                    .opacity(appNameOpacity)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation Logic
    private func startAnimation() {
        #if DEBUG
        print("🎬 [AnimatedSplash] Iniciando animación con degradado retrocedente...")
        #endif

        // Fase 1: Degradado retrocede + Logo aparece (simultáneamente)
        // Degradado: 100% altura → 65% altura (como el header)
        // Logo: Fade in + Scale up
        withAnimation(.easeInOut(duration: gradientAnimationDuration)) {
            gradientHeight = 0.65  // Retrocede al 65% (altura del header)
        }

        // Logo aparece con un ligero delay para mejor timing
        withAnimation(.easeOut(duration: logoAnimationDuration).delay(0.3)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }

        // Fase 2: Mantener visible (totalDisplayDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDisplayDuration) {
            #if DEBUG
            print("🎬 [AnimatedSplash] Iniciando fade out...")
            #endif

            // Fade out de todo
            withAnimation(.easeInOut(duration: fadeOutDuration)) {
                gradientOpacity = 0
                logoOpacity = 0
                appNameOpacity = 0
            }

            // Notificar completado
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
                #if DEBUG
                print("✅ [AnimatedSplash] Animación completada - degradado retrocedió y logo apareció")
                #endif
                onAnimationComplete()
            }
        }
    }
}

// MARK: - Preview
#Preview("Animación Degradado") {
    AnimatedSplashView {
        print("Animation Complete - Gradient retracted successfully")
    }
}
