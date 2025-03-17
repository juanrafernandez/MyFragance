import SwiftUI
import Combine

struct HomeTabView: View {
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel // Make sure BrandViewModel is injected in the environment

    @State private var selectedTabIndex = 0

    // State para la gestión de la presentación de vistas modales
    @State private var selectedPerfume: Perfume? = nil
    @State private var relatedPerfumes: [Perfume] = []
    @State private var isPresentingTestView = false
    @State private var selectedBrandForPerfume: Brand? = nil // NEW: State to hold the Brand for selected perfume

    // Estado para los colores del degradado, inicializado con BLANCO - Subtle default gradient
    @State private var gradientColors: [Color] = [Color("champanOscuro").opacity(0.1), .white]
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan // Default preset

    // Inicializador para configurar la apariencia de UIPageControl
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.2)) // Lighter page indicator
    }

    var body: some View {
        NavigationView { // <-- NavigationView
            ZStack(alignment: .top) { // ZStack para el degradado de fondo
                GradientView(preset: selectedGradientPreset) // Pasa el preset seleccionado a GradientView
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Mostrar saludo solo si hay perfiles
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
            .environmentObject(familiaOlfativaViewModel) // <-- **INJECTA familiaOlfativaViewModel HERE**
            .environmentObject(olfactiveProfileViewModel) // <-- **INJECTA olfactiveProfileViewModel HERE**
            .environmentObject(perfumeViewModel) // <-- **INJECTA perfumeViewModel HERE**
            .environmentObject(brandViewModel) // <-- **INJECTA BrandViewModel HERE - THIS IS KEY!**
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedPerfume) { perfume in
                if let brand = selectedBrandForPerfume { // Corrected if let condition - only check for brand
                    PerfumeDetailView(
                        perfume: perfume, // Use 'perfume' directly
                        relatedPerfumes: relatedPerfumes,
                        brand: brand // Pass the brand here
                    )
                } else {
                    Text("Error loading perfume details: Brand not found") // Handle error if brand is missing
                }
            }
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
            .onChange(of: selectedPerfume) { newPerfume in // Listen for changes in selectedPerfume
                if let perfume = newPerfume {
                    // Fetch the brand using BrandViewModel when a perfume is selected
                    selectedBrandForPerfume = brandViewModel.getBrand(byKey: perfume.brand)
                } else {
                    selectedBrandForPerfume = nil // Clear the brand if selectedPerfume becomes nil
                }
            }
        }
    }

    // MARK: - Función para actualizar los colores del degradado Simplificada - **SIN CAMBIOS**
    private func updateGradientColors(forProfileAtIndex index: Int) {

        guard olfactiveProfileViewModel.profiles.indices.contains(index) else {
            print("🎨 updateGradientColors(forProfileAtIndex: \(index)) - Índice fuera de rango o sin perfiles. APLICANDO DEGRADADO POR DEFECTO.")
            // **APLICAMOS EXPLICITAMENTE EL DEGRADADO POR DEFECTO AQUÍ:**
            gradientColors = [
                Color(white: 0.98),
                Color.white
            ]
            return // Salimos DESPUÉS de asignar el degradado por defecto
        }
        print("🎨 updateGradientColors(Num Profiles: \(olfactiveProfileViewModel.profiles.count))")
        let profile = olfactiveProfileViewModel.profiles[index]
        print("👤 Profile name: \(profile.name)") // Debug print

        // Family colors - Convert hex string to Color
        var familyColors: [Color] = []
        for familyPuntuation in profile.families.prefix(3) {
            if let family = familiaOlfativaViewModel.getFamily(byKey: familyPuntuation.family) {
                let familyColor = family.familyColor // familyColor is a String (hex)
                let color = Color(hex: familyColor) // Convert hex string to Color
                familyColors.append(color)
            }
        }

        if familyColors.isEmpty {
            print("🎨 updateGradientColors - No hay colores de familia. APLICANDO DEGRADADO POR DEFECTO.")
            // **APLICAMOS EXPLICITAMENTE EL DEGRADADO POR DEFECTO TAMBIÉN AQUÍ, POR SI ACASO:**
            gradientColors = [
                Color(white: 0.98),
                Color.white
            ]
            return // Salimos DESPUÉS de asignar el degradado por defecto
        }


        // Gradient stops - Even more subtle opacity
        var stops: [Gradient.Stop] = []
        for (index, color) in familyColors.enumerated() {
            let opacity: Double
            let location: Double

            switch index {
            case 0: // Familia 1: Less opacity than before
                opacity = 0.25 // Reduced opacity
                location = 0.0
            case 1: // Familia 2: Even less opacity
                opacity = 0.10 // Reduced opacity
                location = 0.1
            case 2: // Familia 3: Minimal opacity
                opacity = 0.05 // Reduced opacity
                location = 0.2
            default: // Default case - even more minimal
                opacity = 0.02 // Reduced opacity
                location = 0.3
            }
            stops.append(Gradient.Stop(color: color.opacity(opacity), location: location))
        }

        // Degradado a blanco - More subtle white gradient
        stops.append(Gradient.Stop(color: Color.white.opacity(0.1), location: 0.3)) // Reduced white opacity
        stops.append(Gradient.Stop(color: Color.white, location: 1.0))

        // Aplica los colores al gradient
        gradientColors = stops.map { $0.color }
        print("🎨 updateGradientColors - Degradado de familias aplicado.")
    }

    // MARK: - Función para cargar los perfiles - AHORA ACTUALIZA LOS COLORES AL FINAL
    private func loadProfiles() {
        print("🔄 loadProfiles() - Iniciando carga de perfiles desde ViewModel...") // Mensaje de inicio
        Task { // Usamos Task para llamar a funciones async
            await olfactiveProfileViewModel.loadInitialData() // Llama a la función de carga del ViewModel
            print("✅ loadProfiles() - Llamada a olfactiveProfileViewModel.loadInitialData() completada.") // Mensaje de fin
            updateGradientColors(forProfileAtIndex: 0)
        }
    }

    // MARK: - Sección de introducción y botón para crear perfil (sin cambios)
    private var introductionSection: some View {
        VStack(spacing: 24) {
            Image("welcome")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180) // Slightly smaller welcome image
                .cornerRadius(12)
                .padding(.horizontal, 24) // Increased horizontal padding

            Text("Bienvenido a tu Perfumería Personal")
                .font(.system(size: 24, weight: .light)) // Lighter font weight, slightly larger
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30) // Increased horizontal padding

            Text("""
Aquí podrás descubrir recomendaciones de fragancias personalizadas según tu perfil olfativo.
Crea tu primer perfil para recibir sugerencias y explorar perfumes ideales para ti.
""")
                .font(.system(size: 16, weight: .light)) // Lighter font weight, slightly larger
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30) // Increased horizontal padding

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
            .padding(.horizontal, 30) // Increased horizontal padding

            Spacer()
        }
        .padding(.top, 50) // Increased top padding
        .background(Color.clear) // Importante: Fondo transparente
    }

    // MARK: - TabView para las tarjetas de perfil (sin cambios)
    private var profileTabView: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(olfactiveProfileViewModel.profiles.indices, id: \.self) { index in
                ProfileCard(profile: olfactiveProfileViewModel.profiles[index], perfumeViewModel: perfumeViewModel)
                    .tag(index)
                    .padding(.horizontal, 25) // Increased horizontal padding around card
                    .padding(.vertical, 30)     // Increased vertical padding around card
                    .background(Color.clear) // Fondo transparente
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}
