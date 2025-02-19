import SwiftUI

struct TestOlfativoTabView: View {
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    @State private var isPresentingTestView = false

    var body: some View {
        ZStack { // ZStack for background gradient
            GradientView(gradientColors: [Color("champanOscuro").opacity(0.1), Color("champan").opacity(0.1), Color("champanClaro").opacity(0.1),.white])
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        introText
                        savedProfilesSection
                        startTestButton
                        startGiftSearchButton
                    }
                    .padding()
                    // Removed .background(Color("fondoClaro")) from here
                }
                // Removed .background(Color("fondoClaro")) from here
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isPresentingTestView) {
            TestView(isTestActive: $isPresentingTestView)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        Text("Descubre tu fragancia ideal")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(Color("textoPrincipal"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .horizontal], 16)
            // Removed .background(Color("fondoClaro")) from here
    }

    // MARK: - Intro Text
    private var introText: some View {
        Text("Crea un nuevo perfil, consulta tus perfiles guardados o explora tus búsquedas de regalos.")
            .font(.subheadline)
            .foregroundColor(Color("textoSecundario"))
    }

    // MARK: - Saved Profiles Section
    private var savedProfilesSection: some View {
        sectionWithCards(
            title: "Perfiles Guardados",
            items: olfactiveProfileViewModel.profiles.prefix(3).map { $0 }
        ) { profile in
            Button(action: {
                navigateToTestResult(profile: profile, isFromTest: false)
            }) {
                let familySelected = familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")

                cardView(
                    title: profile.name,
                    description:familySelected?.familyDescription ?? "",
                    gradientColors: [Color(hex: familySelected?.familyColor ?? "#FFFFFF").opacity(0.1), .white]
                )
            }
        }
    }

    // MARK: - Start Test Button
    private var startTestButton: some View {
        Button(action: { isPresentingTestView = true }) {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Iniciar Test Olfativo")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("champan"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Start Gift Search Button
    private var startGiftSearchButton: some View {
        Button(action: {
            // Acción para búsqueda de regalos
        }) {
            HStack {
                Image(systemName: "gift")
                Text("Buscar un Regalo")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("azulSuave"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Navigation Helper
    private func navigateToTestResult(profile: OlfactiveProfile, isFromTest: Bool) {
        // Aquí iría la lógica de navegación al perfil de resultado del test
    }

    // MARK: - Section With Cards
    private func sectionWithCards<Item: Identifiable, Content: View>(
        title: String,
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if items.count > 1 {
                    Text("Ver Todos")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            ForEach(items) { item in
                content(item)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Card View
    private func cardView(title: String, description: String, gradientColors: [Color]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color("textoPrincipal"))
                    .multilineTextAlignment(.leading)

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}
