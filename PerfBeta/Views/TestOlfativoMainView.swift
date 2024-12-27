import SwiftUI

struct TestOlfativoView: View {
    // Mock de perfiles olfativos guardados
    @State private var savedProfiles: [OlfactiveProfile] = [
        OlfactiveProfile(
            name: "Cumpleaños de Ana",
            perfumes: MockPerfumes.perfumes.filter { $0.familia == "amaderados" },
            gradientColors: [Color("amaderadosClaro").opacity(0.2), .white]
        ),
        OlfactiveProfile(
            name: "Verano Fresco",
            perfumes: MockPerfumes.perfumes.filter { $0.familia == "citricos" },
            gradientColors: [Color("cítricosClaro").opacity(0.2), .white]
        ),
        OlfactiveProfile(
            name: "Primavera Floral",
            perfumes: MockPerfumes.perfumes.filter { $0.familia == "florales" },
            gradientColors: [Color("floralesClaro").opacity(0.2), .white]
        ),
        OlfactiveProfile(
            name: "Invierno Elegante",
            perfumes: MockPerfumes.perfumes.filter { $0.familia == "orientales" },
            gradientColors: [Color("orientalesClaro").opacity(0.2), .white]
        )
    ]
    
    // Mock de búsquedas recientes guardadas
    @State private var recentSearches: [GiftSearch] = [
        GiftSearch(name: "Regalo para Marta", description: "Florales y frescos", gradientColors: [Color("floralesClaro").opacity(0.2), .white]),
        GiftSearch(name: "Cumpleaños de Pedro", description: "Amaderados intensos", gradientColors: [Color("amaderadosClaro").opacity(0.2), .white]),
        GiftSearch(name: "Aniversario de Juan", description: "Cítricos con especias", gradientColors: [Color("cítricosClaro").opacity(0.2), .white]),
        GiftSearch(name: "Navidad Especial", description: "Orientales con vainilla", gradientColors: [Color("orientalesClaro").opacity(0.2), .white])
    ]
    
    @State private var itemToDelete: String? // Elemento a eliminar
    @State private var isDeletingProfile = false // Controla si es perfil o búsqueda
    @State private var showDeleteConfirmation = false // Mostrar el popup de confirmación
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    // Encabezado
                    headerView
                    
                    // Sección de Perfiles Guardados
                    if !savedProfiles.isEmpty {
                        sectionTitle("Perfiles Guardados", showSeeAll: savedProfiles.count > 3) {
                            // Navegación a la pantalla completa de perfiles
                            navigateToList(title: "Todos los Perfiles", items: savedProfiles.map { $0.name })
                        }
                        VStack(spacing: 8) {
                            ForEach(savedProfiles.prefix(3), id: \.name) { profile in
                                profileCard(profile: profile)
                            }
                        }
                    } else {
                        emptyStateText("Aún no tienes perfiles guardados. ¡Empieza tu test ahora!")
                    }
                    
                    // Botón para iniciar un nuevo test olfativo
                    Button(action: {
                        // Acción para iniciar un nuevo test olfativo
                    }) {
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
                    .padding(.vertical, 16)
                    
                    // Sección de Búsquedas Recientes
                    if !recentSearches.isEmpty {
                        sectionTitle("Búsquedas Recientes", showSeeAll: recentSearches.count > 3) {
                            // Navegación a la pantalla completa de búsquedas
                            navigateToList(title: "Todas las Búsquedas", items: recentSearches.map { $0.name })
                        }
                        VStack(spacing: 8) {
                            ForEach(recentSearches.prefix(3), id: \.id) { search in
                                searchCard(search: search)
                            }
                        }
                    } else {
                        emptyStateText("No tienes búsquedas guardadas. ¡Empieza a buscar ahora!")
                    }
                    
                    // Botón para buscar un regalo
                    Button(action: {
                        // Acción para buscar un regalo
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
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color("fondoClaro"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text(isDeletingProfile ? "Eliminar Perfil" : "Eliminar Búsqueda"),
                    message: Text("¿Estás seguro de que deseas eliminar este \(isDeletingProfile ? "perfil" : "búsqueda")?"),
                    primaryButton: .destructive(Text("Eliminar")) {
                        if isDeletingProfile {
                            deleteProfile(named: itemToDelete)
                        } else {
                            deleteSearch(named: itemToDelete)
                        }
                        itemToDelete = nil
                    },
                    secondaryButton: .cancel(Text("Cancelar"))
                )
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Descubre tu fragancia ideal")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
            
            Text("Crea un nuevo perfil, consulta tus perfiles guardados o explora tus búsquedas de regalos.")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))
        }
    }
    
    // MARK: - Título de Sección con Botón Ver Todo
    private func sectionTitle(_ title: String, showSeeAll: Bool, seeAllAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("textoPrincipal"))
            
            Spacer()
            
            if showSeeAll {
                Button(action: seeAllAction) {
                    Text("Ver todo")
                        .font(.subheadline)
                        .foregroundColor(Color.blue)
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Navegación a la lista completa
    private func navigateToList(title: String, items: [String]) {
        // Puedes implementar un NavigationLink a una nueva pantalla aquí
        print("Navegar a \(title) con items: \(items)")
    }
    
    // MARK: - Perfiles Guardados
    private func profileCard(profile: OlfactiveProfile) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.subheadline)
                    .foregroundColor(Color("textoPrincipal"))
                Text(descriptionForFamily(profile.perfumes.first?.familia ?? ""))
                    .font(.caption)
                    .foregroundColor(Color("textoSecundario"))
            }
            .padding(.leading, 10)
            
            Spacer()
            
            Button(action: {
                itemToDelete = profile.name
                isDeletingProfile = true
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 55)
        .background(
            LinearGradient(
                gradient: Gradient(colors: profile.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Búsquedas Recientes
    private func searchCard(search: GiftSearch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(search.name)
                    .font(.subheadline)
                    .foregroundColor(Color("textoPrincipal"))
                Text(search.description)
                    .font(.caption)
                    .foregroundColor(Color("textoSecundario"))
            }
            .padding(.leading, 10)
            
            Spacer()
            
            Button(action: {
                itemToDelete = search.name
                isDeletingProfile = false
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 55)
        .background(
            LinearGradient(
                gradient: Gradient(colors: search.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helpers
    private func emptyStateText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(Color("textoSecundario"))
            .multilineTextAlignment(.center)
            .padding()
    }
    
    private func descriptionForFamily(_ family: String) -> String {
        switch family.lowercased() {
        case "amaderados":
            return "Notas cálidas y terrosas con maderas preciosas."
        case "citricos":
            return "Fragancias frescas con notas de limón."
        case "florales":
            return "Aromas suaves y delicados de flores."
        default:
            return "Perfumes únicos con una mezcla especial."
        }
    }
    
    private func deleteProfile(named name: String?) {
        if let name = name, let index = savedProfiles.firstIndex(where: { $0.name == name }) {
            savedProfiles.remove(at: index)
        }
    }
    
    private func deleteSearch(named name: String?) {
        if let name = name, let index = recentSearches.firstIndex(where: { $0.name == name }) {
            recentSearches.remove(at: index)
        }
    }
}

// MARK: - Gift Search Struct
struct GiftSearch: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let gradientColors: [Color]
}
