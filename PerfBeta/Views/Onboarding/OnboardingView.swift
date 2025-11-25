import SwiftUI

// MARK: - Onboarding Type

enum OnboardingPageType {
    case brandStory
    case pyramidEducation
    case familiesAndStart
    case generic(icon: String, title: String, description: String)
}

// MARK: - Onboarding View

struct OnboardingView: View {
    let type: OnboardingType
    let onComplete: () -> Void

    // MARK: - State
    @State private var currentPage = 0
    @State private var showContent = false

    // Mismo fondo que LaunchScreen para continuidad
    private let backgroundColor = Color(red: 0.949, green: 0.933, blue: 0.878)

    private var pageCount: Int {
        switch type {
        case .firstTime: return 3
        case .whatsNew: return 3
        }
    }

    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                headerView
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)

                // MARK: - Page Content
                TabView(selection: $currentPage) {
                    switch type {
                    case .firstTime:
                        OnboardingBrandStoryPage(isActive: currentPage == 0)
                            .tag(0)
                        OnboardingPyramidPage(isActive: currentPage == 1)
                            .tag(1)
                        OnboardingFamiliesPage(isActive: currentPage == 2)
                            .tag(2)

                    case .whatsNew:
                        OnboardingGenericPage(
                            icon: "star.fill",
                            title: "Novedades en Baura",
                            description: "Hemos mejorado la experiencia con nuevas funcionalidades",
                            isActive: currentPage == 0
                        ).tag(0)
                        OnboardingGenericPage(
                            icon: "bolt.fill",
                            title: "Más Rápido que Nunca",
                            description: "Carga instantánea gracias al nuevo sistema de caché inteligente",
                            isActive: currentPage == 1
                        ).tag(1)
                        OnboardingGenericPage(
                            icon: "paintbrush.fill",
                            title: "Diseño Renovado",
                            description: "Una interfaz más elegante y fácil de usar",
                            isActive: currentPage == 2
                        ).tag(2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // MARK: - Page Indicator
                pageIndicator
                    .padding(.bottom, 20)
                    .opacity(showContent ? 1 : 0)

                // MARK: - Bottom Button
                bottomButton
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Logo pequeño
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)

            Spacer()

            // Botón "Saltar"
            if currentPage < pageCount - 1 {
                Button {
                    complete()
                } label: {
                    Text("Saltar")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, 16)
        .frame(height: 60)
    }

    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppColor.brandAccent : AppColor.brandAccent.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: - Bottom Button
    private var bottomButton: some View {
        Button {
            if currentPage < pageCount - 1 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            } else {
                complete()
            }
        } label: {
            HStack(spacing: 8) {
                Text(buttonText)
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: buttonIcon)
                    .font(.system(size: 14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColor.brandAccent)
                    .shadow(color: AppColor.brandAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.white)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, 40)
    }

    private var buttonText: String {
        if currentPage < pageCount - 1 {
            return "Siguiente"
        } else {
            return type == .firstTime ? "Crear mi Perfil" : "Empezar"
        }
    }

    private var buttonIcon: String {
        if currentPage < pageCount - 1 {
            return "arrow.right"
        } else {
            return type == .firstTime ? "sparkles" : "checkmark"
        }
    }

    private func complete() {
        OnboardingManager.shared.markCompleted()
        onComplete()
    }
}

// MARK: - Page 1: Brand Story (Ba + Aura)

struct OnboardingBrandStoryPage: View {
    let isActive: Bool
    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Ilustración/Símbolo
            ZStack {
                // Aura glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColor.accentGold.opacity(0.3),
                                AppColor.accentGold.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1 : 0)

                // Logo central
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
            }
            .padding(.bottom, 32)

            // Título con significado
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("Ba")
                        .foregroundColor(AppColor.accentGold)
                    Text("+")
                        .foregroundColor(AppColor.textTertiary)
                    Text("Aura")
                        .foregroundColor(AppColor.accentGold)
                }
                .font(.custom("Georgia", size: 16))
                .fontWeight(.medium)
                .opacity(animateContent ? 0.8 : 0)

                Text("Baura")
                    .font(.custom("Georgia", size: 36))
                    .fontWeight(.semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 10)
            }
            .padding(.bottom, 24)

            // Descripción poética
            VStack(spacing: 16) {
                Text("La esencia que te define")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.medium)
                    .foregroundColor(AppColor.textPrimary)

                Text("En el antiguo Egipto, el Ba era la esencia única de cada persona. Tu fragancia es tu aura moderna: la huella invisible que dejas en el tiempo y en la memoria de quienes te rodean.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)

            Spacer()
            Spacer()
        }
        .onAppear {
            if isActive { startAnimation() }
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimation() }
        }
    }

    private func startAnimation() {
        animateContent = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            animateContent = true
        }
    }
}

// MARK: - Page 2: Pyramid Education

struct OnboardingPyramidPage: View {
    let isActive: Bool
    @State private var animateContent = false
    @State private var showLayers: [Bool] = [false, false, false]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Pirámide visual
            VStack(spacing: 6) {
                // Salida (top)
                PyramidLayer(
                    title: "Salida",
                    subtitle: "Primeras notas · 15-30 min",
                    icon: "wind",
                    minWidth: 140,
                    color: AppColor.accentGold.opacity(0.4)
                )
                .opacity(showLayers[0] ? 1 : 0)
                .offset(y: showLayers[0] ? 0 : -10)

                // Corazón (middle)
                PyramidLayer(
                    title: "Corazón",
                    subtitle: "Carácter principal · 2-4 horas",
                    icon: "heart.fill",
                    minWidth: 200,
                    color: AppColor.accentGold.opacity(0.6)
                )
                .opacity(showLayers[1] ? 1 : 0)
                .offset(y: showLayers[1] ? 0 : -10)

                // Fondo (base)
                PyramidLayer(
                    title: "Fondo",
                    subtitle: "Base duradera · 6-24 horas",
                    icon: "mountain.2.fill",
                    minWidth: 260,
                    color: AppColor.accentGold.opacity(0.8)
                )
                .opacity(showLayers[2] ? 1 : 0)
                .offset(y: showLayers[2] ? 0 : -10)
            }
            .padding(.bottom, 32)

            // Título
            Text("La Pirámide Olfativa")
                .font(.custom("Georgia", size: 28))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textPrimary)
                .opacity(animateContent ? 1 : 0)
                .padding(.bottom, 16)

            // Descripción
            Text("Cada perfume cuenta una historia en tres actos. Las notas de salida te seducen, el corazón te enamora, y el fondo te acompaña todo el día.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 15)

            Spacer()
            Spacer()
        }
        .onAppear {
            if isActive { startAnimation() }
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimation() }
        }
    }

    private func startAnimation() {
        animateContent = false
        showLayers = [false, false, false]

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            animateContent = true
        }

        // Animar capas de la pirámide secuencialmente
        for index in 0..<3 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2 + Double(index) * 0.15)) {
                showLayers[index] = true
            }
        }
    }
}

// MARK: - Pyramid Layer Component

struct PyramidLayer: View {
    let title: String
    let subtitle: String
    let icon: String
    let minWidth: CGFloat
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(AppColor.textPrimary)

            Text(subtitle)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(minWidth: minWidth)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
        )
    }
}

// MARK: - Page 3: Families & Start

struct OnboardingFamiliesPage: View {
    let isActive: Bool
    @State private var animateContent = false
    @State private var showFamilies = false

    // Familias olfativas según clasificación estándar
    private let families: [(name: String, icon: String, color: Color)] = [
        ("Cítricos", "sun.max.fill", Color(hex: "F4A836")),
        ("Florales", "camera.macro", Color(hex: "E8B4B8")),
        ("Frutales", "leaf.fill", Color(hex: "E07B54")),
        ("Amaderados", "tree.fill", Color(hex: "8B7355")),
        ("Orientales", "sparkles", Color(hex: "C4A962")),
        ("Especiados", "flame.fill", Color(hex: "C45C3E")),
        ("Acuáticos", "drop.fill", Color(hex: "5BA4C9")),
        ("Verdes", "leaf.arrow.triangle.circlepath", Color(hex: "6B8E4E")),
        ("Gourmand", "birthday.cake.fill", Color(hex: "A67B5B"))
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Título arriba
            Text("Familias Olfativas")
                .font(.custom("Georgia", size: 28))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textPrimary)
                .opacity(animateContent ? 1 : 0)
                .padding(.bottom, 24)

            // Grid de familias (3x3)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(families.enumerated()), id: \.offset) { index, family in
                    FamilyBubble(
                        name: family.name,
                        icon: family.icon,
                        color: family.color
                    )
                    .opacity(showFamilies ? 1 : 0)
                    .scaleEffect(showFamilies ? 1 : 0.8)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(0.1 + Double(index) * 0.06),
                        value: showFamilies
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)

            // Descripción motivacional
            VStack(spacing: 10) {
                Text("Cada familia cuenta una historia diferente.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppColor.textSecondary)

                Text("Descubre cuál es la tuya")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 15)

            Spacer()

            // Referencia de clasificación
            Text("Clasificación basada en el estándar de The Fragrance Foundation")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppColor.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
                .opacity(animateContent ? 0.7 : 0)
        }
        .onAppear {
            if isActive { startAnimation() }
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimation() }
        }
    }

    private func startAnimation() {
        animateContent = false
        showFamilies = false

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            animateContent = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showFamilies = true
        }
    }
}

// MARK: - Family Bubble Component

struct FamilyBubble: View {
    let name: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }

            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColor.textPrimary)
        }
    }
}

// MARK: - Generic Page (for What's New)

struct OnboardingGenericPage: View {
    let icon: String
    let title: String
    let description: String
    let isActive: Bool

    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColor.accentGold.opacity(0.2),
                                AppColor.accentGold.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1.0 : 0.8)

                ZStack {
                    Circle()
                        .fill(AppColor.accentGold.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColor.accentGold, AppColor.accentGold.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(animateContent ? 1.0 : 0.8)
            }
            .padding(.bottom, 32)

            // Title
            Text(title)
                .font(.custom("Georgia", size: 28))
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 15)
                .padding(.bottom, 16)

            // Description
            Text(description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 15)

            Spacer()
            Spacer()
        }
        .onAppear {
            if isActive { startAnimation() }
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimation() }
        }
    }

    private func startAnimation() {
        animateContent = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            animateContent = true
        }
    }
}

// MARK: - Preview

#Preview("First Time") {
    OnboardingView(type: .firstTime) {
        print("Onboarding completed")
    }
}

#Preview("What's New") {
    OnboardingView(type: .whatsNew) {
        print("Onboarding completed")
    }
}

#Preview("Page 1 - Brand Story") {
    OnboardingBrandStoryPage(isActive: true)
        .background(Color(red: 0.949, green: 0.933, blue: 0.878))
}

#Preview("Page 2 - Pyramid") {
    OnboardingPyramidPage(isActive: true)
        .background(Color(red: 0.949, green: 0.933, blue: 0.878))
}

#Preview("Page 3 - Families") {
    OnboardingFamiliesPage(isActive: true)
        .background(Color(red: 0.949, green: 0.933, blue: 0.878))
}
