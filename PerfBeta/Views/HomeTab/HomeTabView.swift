import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @State private var selectedTabIndex = 0

    // State para la gestión de la presentación de vistas modales
    @State private var selectedPerfume: Perfume?
    @State private var relatedPerfumes: [Perfume] = []
    @State private var isPresentingTestView = false

    // Estado para controlar la carga de perfiles
    @State private var isLoadingProfiles = true
    
    // Inicializador para configurar la apariencia de UIPageControl
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.3))
    }

    var body: some View {
        NavigationView {
            ZStack { // ZStack para el degradado de fondo
                LinearGradient(gradient: Gradient(colors: [Color("fondoClaro"), Color.white]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Mostrar saludo solo si hay perfiles
                    if !olfactiveProfileViewModel.profiles.isEmpty {
                        GreetingSection(userName: "Juan")
                            .padding([.top, .horizontal], 16)
                            .background(Color.clear) // Fondo transparente
                    }

                    // Contenido desplazable o introducción y botón de creación
                    if isLoadingProfiles {
                        ProgressView() // Muestra un indicador de carga
                            .onAppear {
                                loadProfiles() // Llama a la función para cargar los perfiles
                            }
                    } else if olfactiveProfileViewModel.profiles.isEmpty {
                        introductionSection // Introducción y botón cuando no hay perfiles
                    } else {
                        profileTabView // Muestra el contenido normal si hay perfiles
                    }
                }
                .background(Color.clear) // Fondo transparente
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(perfume: perfume, relatedPerfumes: relatedPerfumes)
            }
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
        }
    }

    // MARK: - Función para cargar los perfiles
    private func loadProfiles() {
        // Simula una carga asíncrona (reemplaza con tu lógica real)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Espera 2 segundos
            // Una vez cargados los perfiles (o fallido el intento), actualiza el estado
            isLoadingProfiles = false
        }
    }
    
    // MARK: - Sección de introducción y botón para crear perfil (sin cambios)
    private var introductionSection: some View {
        VStack(spacing: 24) {
            Image("welcome")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .padding(.horizontal, 16)

            Text("Bienvenido a tu Perfumería Personal")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Text("""
Aquí podrás descubrir recomendaciones de fragancias personalizadas según tu perfil olfativo. 
Crea tu primer perfil para recibir sugerencias y explorar perfumes ideales para ti.
""")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

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
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 40)
        .background(Color.clear) // Importante: Fondo transparente
    }

    // MARK: - TabView para las tarjetas de perfil
    private var profileTabView: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(olfactiveProfileViewModel.profiles.indices, id: \.self) { index in
                ProfileCard(profile: olfactiveProfileViewModel.profiles[index], perfumeViewModel: perfumeViewModel, onPerfumeTap: { perfume in
                    selectedPerfume = perfume
                    relatedPerfumes = perfumeViewModel.perfumes // Ajusta esto según tu lógica
                })
                .tag(index)
                .padding() // Espacio alrededor de cada tarjeta
                .background(Color.clear) // Fondo transparente
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

// MARK: - Tarjeta de Perfil (ProfileCard)
struct ProfileCard: View {
    let profile: OlfactiveProfile // Ajusta el tipo según tu modelo
    @ObservedObject var perfumeViewModel: PerfumeViewModel // Asegúrate de observar cambios
    var onPerfumeTap: (Perfume) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Tu Perfil Olfativo")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal, 16)

            // Recomendaciones
            HomeRecommendationsCarouselView(profiles: [profile], onPerfumeTap: { perfume, selectedProfile in
                onPerfumeTap(perfume)
            })

            // Perfecto para esta temporada
            HomeSeasonalSectionView(allPerfumes: perfumeViewModel.perfumes, onPerfumeTap: { perfume in
                onPerfumeTap(perfume)
            })

            // ¿Sabías que...?
            HomeDidYouKnowSectionView()
        }
        .padding(.top, 16)
        .background(.white)
        .padding(.horizontal)
    }
}

// MARK: - Sección de saludo (sin cambios)
struct GreetingSection: View {
    let userName: String

    var body: some View {
        let greetingMessage = getGreetingMessage(for: userName)
        Text(greetingMessage)
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(Color("textoPrincipal"))
            .frame(maxWidth: .infinity, alignment: .leading)
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
