import SwiftUI
import Combine

struct HomeTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    
    @State private var selectedTabIndex = 0
    @State private var selectedPerfume: Perfume? = nil
    @State private var relatedPerfumes: [Perfume] = []
    @State private var isPresentingTestView = false
    @State private var selectedBrandForPerfume: Brand? = nil
    @State private var selectedProfile: OlfactiveProfile? = nil
    
    @State private var gradientColors: [Color] = [Color("champanOscuro").opacity(0.1), .white]
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.2))
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    if !olfactiveProfileViewModel.profiles.isEmpty {
                        GreetingSection(userName: "Juan")
                            .padding(.horizontal, 25)
                            .padding(.top, 16)
                            .background(Color.clear)
                        profileTabView
                    } else {
                        introductionSection
                    }
                }
                .background(Color.clear)
            }
            .environmentObject(familiaOlfativaViewModel)
            .environmentObject(olfactiveProfileViewModel)
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedPerfume) { perfume in
                if let brand = selectedBrandForPerfume, let profile = selectedProfile {
                    PerfumeDetailView(
                        perfume: perfume,
                        brand: brand,
                        profile: profile
                    )
                } else {
                    Text("Error loading perfume details: Brand or Profile not found")
                }
            }
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
            .onChange(of: selectedPerfume) { newPerfume in
                if let perfume = newPerfume {
                    selectedBrandForPerfume = brandViewModel.getBrand(byKey: perfume.brand)
                    selectedProfile = olfactiveProfileViewModel.profiles.first
                } else {
                    selectedBrandForPerfume = nil
                    selectedProfile = nil
                }
            }
        }
    }

    private func updateGradientColors(forProfileAtIndex index: Int) {
        guard olfactiveProfileViewModel.profiles.indices.contains(index) else {
            gradientColors = [
                Color(white: 0.98),
                Color.white
            ]
            return
        }

        let profile = olfactiveProfileViewModel.profiles[index]
        var familyColors: [Color] = []
        for familyPuntuation in profile.families.prefix(3) {
            if let family = familiaOlfativaViewModel.getFamily(byKey: familyPuntuation.family) {
                let familyColor = family.familyColor
                let color = Color(hex: familyColor)
                familyColors.append(color)
            }
        }

        if familyColors.isEmpty {
            gradientColors = [
                Color(white: 0.98),
                Color.white
            ]
            return
        }

        var stops: [Gradient.Stop] = []
        for (index, color) in familyColors.enumerated() {
            let opacity: Double
            let location: Double

            switch index {
            case 0:
                opacity = 0.25
                location = 0.0
            case 1:
                opacity = 0.10
                location = 0.1
            case 2:
                opacity = 0.05
                location = 0.2
            default:
                opacity = 0.02
                location = 0.3
            }
            stops.append(Gradient.Stop(color: color.opacity(opacity), location: location))
        }

        stops.append(Gradient.Stop(color: Color.white.opacity(0.1), location: 0.3))
        stops.append(Gradient.Stop(color: Color.white, location: 1.0))

        gradientColors = stops.map { $0.color }
    }

    private func loadProfiles() {
        Task {
            await olfactiveProfileViewModel.loadInitialData()
            updateGradientColors(forProfileAtIndex: 0)
        }
    }

    private var introductionSection: some View {
        VStack(spacing: 24) {
            Image("welcome")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)
                .cornerRadius(12)
                .padding(.horizontal, 24)

            Text("Bienvenido a tu Perfumería Personal")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Text("""
            Aquí podrás descubrir recomendaciones de fragancias personalizadas según tu perfil olfativo.
            Crea tu primer perfil para recibir sugerencias y explorar perfumes ideales para ti.
            """)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button(action: {
                isPresentingTestView = true
            }) {
                Text("Crear mi Perfil Olfativo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("champan"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)

            Spacer()
        }
        .padding(.top, 50)
        .background(Color.clear)
    }

    private var profileTabView: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(olfactiveProfileViewModel.profiles.indices, id: \.self) { index in
                ProfileCard(profile: olfactiveProfileViewModel.profiles[index], perfumeViewModel: perfumeViewModel, selectedPerfume: $selectedPerfume)
                    .tag(index)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 30)
                    .background(Color.clear)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}
