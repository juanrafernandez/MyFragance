import SwiftUI

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

// MARK: - Onboarding View

struct OnboardingView: View {
    let type: OnboardingType
    let onComplete: () -> Void

    @State private var currentPage = 0

    /// Páginas del onboarding según el tipo
    var pages: [OnboardingPage] {
        switch type {
        case .firstTime:
            return firstTimePages
        case .whatsNew:
            return whatsNewPages
        }
    }

    private var firstTimePages: [OnboardingPage] {
        [
            OnboardingPage(
                image: "welcome",
                title: "Bienvenido a MyFragrance",
                description: "Descubre perfumes personalizados según tu perfil olfativo único"
            ),
            OnboardingPage(
                image: "fragance_illustration",
                title: "Crea tu Perfil Olfativo",
                description: "Responde un test personalizado y recibe recomendaciones de fragancias ideales para ti"
            ),
            OnboardingPage(
                image: "family_woody",
                title: "Tu Colección Personal",
                description: "Guarda tus perfumes favoritos, crea tu wishlist y lleva un registro de tus fragancias"
            )
        ]
    }

    private var whatsNewPages: [OnboardingPage] {
        // TODO: Configurar páginas para versión 1.4.0 o futuras
        // Por ahora retorna las mismas páginas que firstTime
        return firstTimePages
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Botón "Saltar" arriba derecha
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            complete()
                        } label: {
                            Text("Saltar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 60)

                Spacer()

                // Páginas con TabView
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(maxHeight: .infinity)

                Spacer()

                // Botón "Siguiente" / "Empezar"
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        complete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Siguiente" : "Empezar")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color("champan"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }

    private func complete() {
        OnboardingManager.shared.markCompleted()
        onComplete()
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            // Imagen
            Image(page.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 280)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)

            // Título
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Descripción
            Text(page.description)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(type: .firstTime) {
        print("Onboarding completed")
    }
}
