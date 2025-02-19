import SwiftUI
import Combine

struct HomeTabView: View {
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel

    @State private var selectedTabIndex = 0

    // State para la gestión de la presentación de vistas modales
    @State private var selectedPerfume: Perfume?
    @State private var relatedPerfumes: [Perfume] = []
    @State private var isPresentingTestView = false

    // Estado para los colores del degradado, inicializado con BLANCO - Subtle default gradient
    @State private var gradientColors: [Color] = [Color("champanOscuro").opacity(0.1), .white]

    // Inicializador para configurar la apariencia de UIPageControl
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.2)) // Lighter page indicator
    }

    var body: some View {
        NavigationView { // <-- NavigationView
            ZStack(alignment: .top) { // ZStack para el degradado de fondo
                GradientView(gradientColors: [Color("champanOscuro").opacity(0.1), Color("champan").opacity(0.1), Color("champanClaro").opacity(0.1),.white]) // Usa GradientView como fondo
                    .edgesIgnoringSafeArea(.all) // Para que ocupe toda la pantalla

                VStack(spacing: 0) {
                    // Mostrar saludo solo si hay perfiles
                    if !olfactiveProfileViewModel.profiles.isEmpty {
                        GreetingSection(userName: "Juan")
                            .padding([.top, .horizontal], 25)
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
                PerfumeDetailView(perfume: perfume, relatedPerfumes: relatedPerfumes)
            }
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
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

// MARK: - Tarjeta de Perfil (ProfileCard)
struct ProfileCard: View {
    let profile: OlfactiveProfile
    @ObservedObject var perfumeViewModel: PerfumeViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: 0) {

                    VStack { // Contenedor para el nombre y las familias
                        Text("PERFIL".uppercased()) // Basic Text - no extra padding
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color("textoSecundario"))

                        Text(profile.name)
                            .font(.system(size: 50, weight: .ultraLight))
                            .foregroundColor(Color("textoPrincipal"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 5)
                            .lineLimit(2) //Debe ser removido

                        Text(profile.families.prefix(3).map { $0.family }.joined(separator: ", ").capitalized)
                            .font(.system(size: 18, weight: .thin))
                            .foregroundColor(Color("textoSecundario"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                      //.frame(maxHeight: geometry.size.height * 0.25) // El alto se ajusta automatico

                    Spacer() // Empuja el siguiente contenido hacia la parte inferior

                    VStack(alignment: .center, spacing: 0) {
                        PerfumeCarouselView(allPerfumes: perfumeViewModel.perfumes, onPerfumeTap: { perfume in })
                            .frame(height: geometry.size.height * 0.38)
                            .padding(.bottom, 1)

                        VStack {
                            HomeDidYouKnowSectionView()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 35)
                    }
                }
                .padding(.top, 24)
            }
        }
    }
}

// MARK: - Carrusel Horizontal de Perfumes (sin cambios)
struct PerfumeCarouselView: View {
    let allPerfumes: [Perfume]
    var onPerfumeTap: ((Perfume) -> Void)? = nil

    var body: some View {
        VStack(spacing: 15) { // VStack - Leading alignment
            HStack(alignment: .center) { // HStack - Center alignment
                Text("RECOMENDADOS PARA TI".uppercased()) // Basic Text - no extra padding
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))

                Spacer() // Spacer to push button to the right

                Button("Ver todos") { // Basic Button - minimal styling
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

            ScrollView(.horizontal, showsIndicators: false) { // Added ScrollView for horizontal scrolling
                HStack(alignment: .top, spacing: 8) { // **Added alignment: .top to HStack**
                    ForEach(allPerfumes.prefix(3), id: \.id) { perfume in
                        PerfumeCarouselItem(perfume: perfume)
                            .frame(width: 100) // **Further reduced item width to 100**
                            .onTapGesture {
                                onPerfumeTap?(perfume)
                            }
                    }
                }
                .padding(.horizontal, 18) // Padding between perfume items
            }
        }
        .padding(.top, 15) // Top padding for the whole section
    }
}

struct PerfumeCarouselItem: View {
    let perfume: Perfume
    @EnvironmentObject var brandViewModel: BrandViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            ZStack(alignment: .topTrailing) { // ZStack para superponer el porcentaje
                Image("perfume_bottle_placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // **Further reduced image size to 80x80**
                    .cornerRadius(12)

                Text("95%") // Porcentaje de ajuste al perfil (puedes usar un valor dinámico)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.green) // Color de fondo del porcentaje
                    .cornerRadius(6)
            }

            Text(perfume.name)
                .font(.system(size: 12, weight: .thin))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 6) // **Reduced top padding for text to 6**

            let brandKey = perfume.brand
            if let brand = brandViewModel.getBrand(byKey: brandKey) {
                Text(brand.name.capitalized)
                    .font(.system(size: 10, weight: .thin)) // **Reduced brand name font size to 9**
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text("Brand N/A")
                    .font(.system(size: 9, weight: .thin)) // **Reduced brand name font size to 9**
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Sección de saludo - Refined Greeting (sin cambios)
struct GreetingSection: View {
    let userName: String

    var body: some View {
        let greetingMessage = getGreetingMessage(for: userName)
        Text(greetingMessage)
            .font(.system(size: 18, weight: .thin)) // Thinner, slightly larger font
            .foregroundColor(Color("textoSecundario")) // Use textoSecundario for subtlety
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4) // Added slight bottom padding for spacing
    }

    func getGreetingMessage(for name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 12 {
            return "Buenos días, \(name)".uppercased()
        } else if hour >= 12 && hour < 18 {
            return "Buenas tardes, \(name)".uppercased()
        } else {
            return "Buenas noches, \(name)".uppercased()
        }
    }
}


// MARK: - Sección ¿Sabías que...? - Refined "Did You Know" (sin cambios)
struct HomeDidYouKnowSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Added spacing in VStack
            Divider()
                .frame(height: 0.5) // Thinner divider
                .overlay(Color("textoSecundario").opacity(0.3)) // Lighter divider color
                .padding(.vertical, 12) // Increased vertical padding around divider
                .padding(.horizontal, 50)
            
            Text("¿SABÍAS QUE...?")
                .font(.system(size: 12, weight: .light)) // Lighter, smaller font
                .foregroundColor(Color("textoSecundario")) // Use textoSecundario for subtlety
                .padding(.bottom, 6) // Increased bottom padding

            Text("La vainilla es uno de los ingredientes más caros de la perfumería, apreciada por su aroma cálido y dulce.")
                .font(.system(size: 13, weight: .thin)) // **Reduced font size to 13 for "Did you know" text**
                .foregroundColor(Color("textoSecundario")) // Use textoSecundario for subtlety
        }
    }
}
