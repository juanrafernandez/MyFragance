import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var selectedPerfume: Perfume? // Perfume seleccionado para detalle
    @State private var relatedPerfumes: [Perfume] = [] // Perfumes relacionados al seleccionado
    @State private var isPresentingTestView = false // Controla si se muestra TestView

    init() {
        // Cambia el color de los indicadores
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("textoPrincipal"))
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("textoSecundario").opacity(0.3))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mostrar saludo solo si hay perfiles
                if !olfactiveProfileViewModel.profiles.isEmpty {
                    GreetingSection(userName: "Juan")
                        .padding([.top, .horizontal], 16)
                        .background(Color("fondoClaro"))
                }

                // Contenido desplazable o introducción y botón de creación
                if olfactiveProfileViewModel.profiles.isEmpty {
                    introductionSection // Introducción y botón cuando no hay perfiles
                } else {
                    profileContent // Muestra el contenido normal si hay perfiles
                }
            }
            .background(Color("fondoClaro"))
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(perfume: perfume, relatedPerfumes: relatedPerfumes)
            }
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
        }
    }

    // MARK: - Sección de introducción y botón para crear perfil
    private var introductionSection: some View {
        VStack(spacing: 24) {
            // Imagen decorativa de bienvenida
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
        .background(Color("fondoClaro"))
    }

    // MARK: - Contenido del perfil
    private var profileContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recomendaciones
                HomeRecommendationsCarouselView(profiles: olfactiveProfileViewModel.profiles, onPerfumeTap: { perfume, selectedProfile in
                    selectedPerfume = perfume
                    relatedPerfumes = perfumeViewModel.getRelatedPerfumes(for: selectedProfile)
                })

                // Perfecto para esta temporada
                HomeSeasonalSectionView(allPerfumes: perfumeViewModel.perfumes, onPerfumeTap: { perfume in
                    selectedPerfume = perfume
                    relatedPerfumes = perfumeViewModel.perfumes // Puedes ajustar según la lógica
                })

                // ¿Sabías que...?
                HomeDidYouKnowSectionView()
            }
            .padding(.top, 16)
            .background(Color("fondoClaro"))
        }
    }
}

// MARK: - Sección de saludo
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
            return "Buenos días, \(name). ¿Qué fragancia buscas hoy?"
        } else if hour >= 12 && hour < 18 {
            return "Buenas tardes, \(name). ¿Buscas algo fresco para la tarde?"
        } else {
            return "Buenas noches, \(name). ¿Buscas nueva fragancia?"
        }
    }
}
