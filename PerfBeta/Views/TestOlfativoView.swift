import SwiftUI

struct TestOlfativoView: View {
    @EnvironmentObject var profileManager: OlfactiveProfileManager
    @State private var recentSearches: [GiftSearch] = mockSearches

    @State private var isPresentingTestView = false
    @State private var isPresentingGiftView = false
    @State private var navigationPath: [NavigationDestination] = []

    enum NavigationDestination: Hashable {
        case profilesList
        case searchesList
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Text("Descubre tu fragancia ideal")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("textoPrincipal"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .horizontal], 16)
                    .background(Color("fondoClaro"))

                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Crea un nuevo perfil, consulta tus perfiles guardados o explora tus búsquedas de regalos.")
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))

                        // Perfiles guardados
                        sectionWithCards(
                            title: "Perfiles Guardados",
                            items: Array(profileManager.profiles.prefix(3)),
                            seeAllAction: { navigationPath.append(.profilesList) },
                            content: { profile in
                                cardView(title: profile.name, description: profile.familia.descripcion, gradientColors: [Color(hex: profile.familia.color).opacity(0.1), .white])
                            }
                        )

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
                        .padding(.vertical, 5)
                        .fullScreenCover(isPresented: $isPresentingTestView) {
                            NavigationStack {
                                TestView(isTestActive: $isPresentingTestView)
                            }
                        }

                        // Búsquedas recientes
                        sectionWithCards(
                            title: "Búsquedas Recientes",
                            items: Array(recentSearches.prefix(3)),
                            seeAllAction: { navigationPath.append(.searchesList) },
                            content: { search in
                                cardView(title: search.name, description: search.description, gradientColors: search.gradientColors)
                            }
                        )

                        Button(action: { isPresentingGiftView = true }) {
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
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .fullScreenCover(isPresented: $isPresentingGiftView) {
                            NavigationStack {
                                GiftView()
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading) {
                                            Button(action: { isPresentingGiftView = false }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color("fondoClaro"))
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .profilesList:
                    ProfilesListView()
                case .searchesList:
                    SearchesListView(recentSearches: $recentSearches)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func sectionWithCards<Item: Identifiable, Content: View>(
        title: String,
        items: [Item],
        seeAllAction: @escaping () -> Void,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if items.count > 1 {
                    Button(action: seeAllAction) {
                        Text("Ver Todos")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            ForEach(items) { item in
                content(item)
            }
        }
        .padding(.top, 16)
    }

    private func cardView(title: String, description: String, gradientColors: [Color]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color("textoPrincipal"))
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color("textoSecundario"))
            }
            .padding(.leading, 10)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 55)
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
