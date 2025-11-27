import SwiftUI

/// Componente unificado para estados de carga en toda la app
/// Soporta múltiples estilos: inline, overlay, fullScreen, skeleton
struct LoadingView: View {
    // MARK: - Properties
    let message: String?
    let style: LoadingStyle

    // MARK: - Enums
    enum LoadingStyle {
        case inline         // Para usar dentro de una sección (pequeño)
        case overlay        // Overlay semitransparente sobre contenido
        case fullScreen     // Cubre toda la pantalla
        case skeleton       // Placeholder animado (para listas)
    }

    // MARK: - Initializers
    init(message: String? = nil, style: LoadingStyle = .inline) {
        self.message = message
        self.style = style
    }

    // MARK: - Body
    var body: some View {
        switch style {
        case .inline:
            inlineView
        case .overlay:
            overlayView
        case .fullScreen:
            fullScreenView
        case .skeleton:
            skeletonView
        }
    }

    // MARK: - Style Variations

    /// Inline loading - para usar dentro de contenido existente (Estilo Editorial)
    private var inlineView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppColor.brandAccent)

            if let message = message {
                Text(message)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    /// Overlay loading - sobre contenido con fondo semitransparente (Estilo Editorial)
    private var overlayView: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Loading card
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppColor.brandAccent)

                if let message = message {
                    Text(message)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.95))
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
    }

    /// Full screen loading - cubre toda la pantalla (Estilo Editorial)
    private var fullScreenView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColor.brandAccent)

            if let message = message {
                Text(message)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    /// Skeleton loading - placeholder animado
    private var skeletonView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 12) {
                    // Imagen placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)

                    // Texto placeholder
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 12)
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .redacted(reason: .placeholder)
        .shimmering() // Animación shimmer
    }
}

// MARK: - Shimmer Effect
extension View {
    /// Añade efecto shimmer (brillante animado) al placeholder
    @ViewBuilder
    func shimmering(active: Bool = true, duration: Double = 1.5) -> some View {
        if active {
            modifier(ShimmerModifier(duration: duration))
        } else {
            self
        }
    }
}

/// Modifier que crea el efecto shimmer
struct ShimmerModifier: ViewModifier {
    let duration: Double
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: phase * geometry.size.width)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Convenience Initializers
extension LoadingView {
    /// Loading inline sin mensaje
    static var inline: LoadingView {
        LoadingView(message: nil, style: .inline)
    }

    /// Loading inline con mensaje
    static func inline(_ message: String) -> LoadingView {
        LoadingView(message: message, style: .inline)
    }

    /// Loading overlay sin mensaje
    static var overlay: LoadingView {
        LoadingView(message: nil, style: .overlay)
    }

    /// Loading overlay con mensaje
    static func overlay(_ message: String) -> LoadingView {
        LoadingView(message: message, style: .overlay)
    }

    /// Loading fullScreen sin mensaje
    static var fullScreen: LoadingView {
        LoadingView(message: nil, style: .fullScreen)
    }

    /// Loading fullScreen con mensaje
    static func fullScreen(_ message: String) -> LoadingView {
        LoadingView(message: message, style: .fullScreen)
    }

    /// Skeleton loader
    static var skeleton: LoadingView {
        LoadingView(message: nil, style: .skeleton)
    }
}

// MARK: - View Extension para uso conveniente
extension View {
    /// Aplica loading overlay sobre la vista actual
    /// - Parameters:
    ///   - isLoading: Binding que controla si se muestra el loading
    ///   - message: Mensaje opcional a mostrar
    func loading(_ isLoading: Bool, message: String? = nil) -> some View {
        ZStack {
            self

            if isLoading {
                LoadingView(message: message, style: .overlay)
            }
        }
    }
}

// MARK: - Preview
#Preview("Inline Loading") {
    VStack(spacing: 40) {
        Text("Inline sin mensaje:")
        LoadingView.inline

        Divider()

        Text("Inline con mensaje:")
        LoadingView.inline("Cargando perfumes...")
    }
    .padding()
}

#Preview("Overlay Loading") {
    ZStack {
        // Contenido de fondo
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<10) { i in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 100)
                        .overlay {
                            Text("Contenido \(i + 1)")
                        }
                }
            }
            .padding()
        }

        // Loading overlay
        LoadingView.overlay("Guardando tu perfil...")
    }
}

#Preview("Full Screen Loading") {
    LoadingView.fullScreen("Cargando tu biblioteca personal...")
}

#Preview("Skeleton Loading") {
    LoadingView.skeleton
}

#Preview("View Extension - Loading Modifier") {
    struct LoadingDemo: View {
        @State private var isLoading = false

        var body: some View {
            VStack(spacing: 20) {
                Text("Contenido de la vista")
                    .font(.title)

                Button("Simular Carga") {
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .loading(isLoading, message: "Procesando...")
        }
    }

    return LoadingDemo()
}

#Preview("All Styles Comparison") {
    TabView {
        LoadingView.inline("Inline style")
            .tabItem {
                Label("Inline", systemImage: "1.circle")
            }

        ZStack {
            Color.blue.opacity(0.1)
            LoadingView.overlay("Overlay style")
        }
        .tabItem {
            Label("Overlay", systemImage: "2.circle")
        }

        LoadingView.fullScreen("Full screen style")
            .tabItem {
                Label("Full", systemImage: "3.circle")
            }

        LoadingView.skeleton
            .tabItem {
                Label("Skeleton", systemImage: "4.circle")
            }
    }
}
