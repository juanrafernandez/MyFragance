import SwiftUI

enum TestTabSection: String, CaseIterable {
    case olfactiveProfiles = "Perfiles Olfativos"
    case giftSearches = "Búsquedas de Regalo"
}

struct TestOlfativoTabView: View {
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel

    @State private var selectedTab: TestTabSection = .olfactiveProfiles
    @State private var isPresentingTestView = false
    @State private var isPresentingGiftFlow = false
    // ✅ ELIMINADO: Sistema de temas personalizable
    @State private var selectedProfileForNavigation: OlfactiveProfile? = nil
    @State private var isPresentingResultAsFullScreenCover = false
    @State private var navigationLinkActive = false

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    headerView

                    // Tab Picker
                    Picker("", selection: $selectedTab) {
                        ForEach(TestTabSection.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 25)
                    .padding(.top, 12)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            if selectedTab == .olfactiveProfiles {
                                olfactiveProfilesContent
                            } else {
                                giftSearchesContent
                            }
                        }
                        .padding(.horizontal, 25)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: ProfileManagementView()
                        .environmentObject(olfactiveProfileViewModel),
                    isActive: $navigationLinkActive,
                    label: { EmptyView() }
                )
            )
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
            .fullScreenCover(isPresented: $isPresentingGiftFlow) {
                GiftFlowView()
                    .environmentObject(giftRecommendationViewModel)
                    .environmentObject(perfumeViewModel)
                    .environmentObject(brandViewModel)  // ✅ Ya está pasando brandViewModel
            }
            .fullScreenCover(isPresented: $isPresentingResultAsFullScreenCover) {
                if let profileToDisplay = selectedProfileForNavigation {
                    TestResultFullScreenView(profile: profileToDisplay)
                } else {
                    Text("Error: No se pudo cargar el perfil guardado.")
                }
            }
            .onChange(of: selectedProfileForNavigation) {
                #if DEBUG
                print("Selected profile changed: \(String(describing: selectedProfileForNavigation?.name))")
                #endif
            }
            .onAppear {
                PerformanceLogger.logViewAppear("TestOlfativoTabView")

                // ✅ Lazy load: Cargar families solo cuando se necesitan
                Task {
                    if familyViewModel.familias.isEmpty {
                        await familyViewModel.loadInitialData()
                        #if DEBUG
                        print("✅ [TestTab] Families loaded on-demand")
                        #endif
                    }

                    // ✅ Cargar perfiles de regalo guardados
                    await giftRecommendationViewModel.loadProfiles()
                    #if DEBUG
                    print("✅ [TestTab] Gift profiles loaded")
                    #endif
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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

    // MARK: - Tab Content Views

    private var olfactiveProfilesContent: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Crea un nuevo perfil olfativo o consulta tus perfiles guardados.")
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .padding(.top, 15)

            savedProfilesSection
            startTestButton
        }
    }

    private var giftSearchesContent: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Encuentra el perfume perfecto para regalar. Guarda tus búsquedas para consultarlas después.")
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .padding(.top, 15)

            savedGiftProfilesSection
            startGiftSearchButton
        }
    }

    // MARK: - Deprecated (keeping for reference)
    private var introText: some View {
        Text("Crea un nuevo perfil, consulta tus perfiles guardados o explora tus búsquedas de regalos.")
            .font(.system(size: 15, weight: .thin))
            .foregroundColor(Color("textoSecundario"))
    }

    private var savedProfilesSection: some View {
        sectionWithCards(
            title: "Perfiles Guardados",
            items: olfactiveProfileViewModel.profiles.prefix(3).map { $0 }
        ) { profile in
            Button(action: {
                navigateToTestResult(profile: profile, isFromTest: false)
            }) {
                let familySelected = familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")

                ProfileCardView(
                    title: profile.name,
                    description: familySelected?.familyDescription ?? "",
                    gradientColors: [Color(hex: familySelected?.familyColor ?? "#FFFFFF").opacity(0.1), .white]
                )
            }
        }
    }

    private var savedGiftProfilesSection: some View {
        sectionWithCards(
            title: "Perfiles de Regalo Guardados",
            items: giftRecommendationViewModel.savedProfiles.prefix(3).map { $0 }
        ) { profile in
            Button(action: {
                // TODO: Navegar a los detalles del perfil de regalo
                giftRecommendationViewModel.loadProfile(profile)
                // Mostrar resultados
            }) {
                ProfileCardView(
                    title: profile.displayName,
                    description: profile.summary,
                    gradientColors: [Color("champan").opacity(0.1), .white]
                )
            }
        }
    }

    private var giftSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BÚSQUEDAS DE REGALOS".uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                Button("Ver todos") {
                    navigationLinkActive = true
                }
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("champan").opacity(0.1))
                )
                .cornerRadius(8)
            }

            if giftRecommendationViewModel.savedProfiles.isEmpty {
                Text("Aún no has guardado búsquedas de regalos. ¡Pulsa el botón 'Buscar un Regalo' para empezar y guarda tus búsquedas aquí!")
                    .font(.system(size: 13, weight: .thin, design: .default))
                    .foregroundColor(Color("textoSecundario"))
                    .padding(.vertical, 8)
            } else {
                Text("No hay búsquedas de regalos guardadas aún.")
                    .font(.system(size: 13, weight: .thin, design: .default))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 5)
    }

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

    private var startGiftSearchButton: some View {
        Button(action: {
            isPresentingGiftFlow = true
        }) {
            HStack {
                Image(systemName: "gift")
                Text("Buscar un Regalo")
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

    private func navigateToTestResult(profile: OlfactiveProfile, isFromTest: Bool) {
        selectedProfileForNavigation = profile
        DispatchQueue.main.async {
            self.isPresentingTestView = false
            self.isPresentingResultAsFullScreenCover = true
        }
    }

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
                if items.count > 0 {
                    Button("Ver todos") {
                        navigationLinkActive = true
                    }
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("textoPrincipal"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("champan").opacity(0.1))
                    )
                    .cornerRadius(8)
                }
            }
            ForEach(items) { item in
                content(item)
            }
        }
        .padding(.top, 5)
    }
}
