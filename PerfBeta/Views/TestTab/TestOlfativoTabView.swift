import SwiftUI

struct TestOlfativoTabView: View {
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    @State private var isPresentingTestView = false
    @State private var giftSearches: [String] = [] // Placeholder for gift searches - replace with actual data source
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan // Default preset
    
    var body: some View {
        ZStack { // ZStack for background gradient
            GradientView(preset: selectedGradientPreset) // Pasa el preset seleccionado a GradientView
                    .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        introText
                            .padding(.top, 15)
                        savedProfilesSection
                        startTestButton
                        giftSearchesSection
                        startGiftSearchButton 
                    }
                    .padding(.horizontal,25)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isPresentingTestView) {
            TestView(isTestActive: $isPresentingTestView)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Descubre tu fragancia ideal".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
            Spacer()
        }
        .padding(.leading, 25)
        .padding(.top, 16)
    }

    // MARK: - Intro Text
    private var introText: some View {
        Text("Crea un nuevo perfil, consulta tus perfiles guardados o explora tus búsquedas de regalos.")
            .font(.system(size: 15, weight: .thin))
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

    // MARK: - Gift Searches Section
    private var giftSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BÚSQUEDAS DE REGALOS".uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
            }

            if giftSearches.isEmpty { // Conditional text for empty list
                Text("Aún no has guardado búsquedas de regalos. ¡Pulsa el botón 'Buscar un Regalo' para empezar y guarda tus búsquedas aquí!")
                    .font(.system(size: 13, weight: .thin, design: .default))
                    .foregroundColor(Color("textoSecundario"))
                    .padding(.vertical, 8)
            } else {
                // TODO: Display gift search items here when implemented
                Text("No hay búsquedas de regalos guardadas aún.") // Placeholder for when gift search functionality is implemented
                    .font(.system(size: 13, weight: .thin, design: .default))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 5)
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
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if items.count > 1 {
                    Button("Ver todos") {
                        print("Ver todos button tapped!")
                    }
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("textoPrincipal"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("champan").opacity(0.1))
                    )
                }
            }
            ForEach(items) { item in
                content(item)
            }
        }
        .padding(.top, 5)
    }

    // MARK: - Card View
    private func cardView(title: String, description: String, gradientColors: [Color]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color("textoPrincipal"))
                    .multilineTextAlignment(.leading)

                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
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
