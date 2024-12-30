import SwiftUI

struct TestResultView: View {
    let title: String
    let summary: [(String, String)] // Preguntas y respuestas
    let profileName: String?
    let profileDescription: String
    let profileGradient: [Color]
    let profileIcon: String
    let recommendedPerfumes: [Perfume]
    let isFromTest: Bool

    @Binding var isTestActive: Bool // Controla el cierre completo del flujo del test
    @EnvironmentObject var giftManager: GiftManager
    @EnvironmentObject var profileManager: OlfactiveProfileManager
    @State private var isSavePopupVisible = false
    @State private var isCloseConfirmationVisible = false
    @State private var isAccordionExpanded = false
    @State private var saveName: String = ""

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Título
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(hex: "#2D3748"))
                                .multilineTextAlignment(.center)
                                .padding(.top, 16)

                            // Perfil recomendado
                            VStack(spacing: 16) {
                                ZStack {
                                    LinearGradient(colors: profileGradient, startPoint: .top, endPoint: .bottom)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    VStack(spacing: 8) {
                                        Text(profileName ?? "Perfil Desconocido")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(Color(hex: "#2D3748"))
                                        Text(profileDescription)
                                            .font(.body)
                                            .foregroundColor(Color(hex: "#4A5568"))
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            }

                            // Perfumes recomendados
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Perfumes Recomendados")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#2D3748"))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(recommendedPerfumes, id: \.id) { perfume in
                                            VStack(spacing: 8) {
                                                Image(perfume.image_name)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 100, height: 120)
                                                    .cornerRadius(8)

                                                Text(perfume.nombre)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .multilineTextAlignment(.center)

                                                Text(perfume.familia.capitalized)
                                                    .font(.caption)
                                                    .foregroundColor(Color(hex: "#4A5568"))
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.horizontal)

                            // Resumen del Test (Acordeón)
                            AccordionView(isExpanded: $isAccordionExpanded) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(summary.indices, id: \.self) { index in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(summary[index].0)
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "#2D3748"))
                                                .fontWeight(.semibold)
                                            Text(summary[index].1)
                                                .font(.body)
                                                .foregroundColor(Color(hex: "#4A5568"))

                                            if index != summary.count - 1 {
                                                Divider()
                                                    .background(Color(hex: "#E2E8F0"))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .id("Accordion") // Identificador para el scroll
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            .onChange(of: isAccordionExpanded) { expanded in
                                if expanded {
                                    withAnimation {
                                        proxy.scrollTo("Accordion", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Espaciado dinámico entre el AccordionView y el botón "Guardar Perfil"
                    if isAccordionExpanded {
                        Spacer().frame(height: 24) // Añadir un margen adicional cuando el Accordion está expandido
                    }
                    
                    // Botón Guardar
                    if isFromTest {
                        Button(action: {
                            isSavePopupVisible = true
                        }) {
                            Text("Guardar Perfil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#F6AD55"))
                                .foregroundColor(.white)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
                .navigationTitle(profileName ?? "Resultados")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            isCloseConfirmationVisible = true
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .alert("¿Seguro que quieres salir sin guardar?", isPresented: $isCloseConfirmationVisible) {
                    Button("Salir", role: .destructive) {
                        isTestActive = false // Cerrar todas las pantallas relacionadas con el test
                    }
                    Button("Cancelar", role: .cancel) { }
                }
                .sheet(isPresented: $isSavePopupVisible) {
                    VStack(spacing: 16) {
                        Text("Guardar Perfil")
                            .font(.headline)
                            .padding(.top)

                        TextField("Nombre del perfil (máx. 18 caracteres)", text: $saveName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: saveName) { newValue in
                                if newValue.count > 18 {
                                    saveName = String(newValue.prefix(18))
                                }
                            }
                            .padding()

                        Button(action: {
                            saveProfileOrSearch()
                        }) {
                            Text("Guardar")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#F6AD55"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Button("Cancelar", role: .cancel) {
                            isSavePopupVisible = false
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func saveProfileOrSearch() {
        if isFromTest {
            let newProfile = OlfactiveProfile(
                name: saveName,
                perfumes: recommendedPerfumes,
                familia: FamiliaOlfativa(
                    id: "custom",
                    nombre: profileName ?? "Desconocido",
                    descripcion: profileDescription,
                    notasClave: [],
                    ingredientesAsociados: [],
                    intensidadPromedio: "Media",
                    estacionRecomendada: [],
                    personalidadAsociada: [],
                    color: "#FFFAF0"
                ),
                description: profileDescription,
                icon: profileIcon
            )
            profileManager.addProfile(newProfile)
        } else {
            let newSearch = GiftSearch(
                id: UUID(),
                name: saveName,
                description: profileDescription,
                perfumes: recommendedPerfumes,
                familia: FamiliaOlfativa(
                    id: "custom",
                    nombre: profileName ?? "Desconocido",
                    descripcion: profileDescription,
                    notasClave: [],
                    ingredientesAsociados: [],
                    intensidadPromedio: "Media",
                    estacionRecomendada: [],
                    personalidadAsociada: [],
                    color: "#FFFAF0"
                ),
                icon: profileIcon
            )
            giftManager.addSearch(newSearch)
        }
        isSavePopupVisible = false
        isTestActive = false // Cerrar todas las pantallas relacionadas con el test
    }
}

// Componente para el acordeón
struct AccordionView<Content: View>: View {
    @Binding var isExpanded: Bool
    let content: Content

    init(isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack {
            HStack {
                Text("Resumen del Test")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#2D3748"))
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .animation(.easeInOut, value: isExpanded)
            }
            .padding()
            .onTapGesture {
                isExpanded.toggle()
            }

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .slide))
            }
        }
    }
}
