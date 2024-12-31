import SwiftUI

struct TestResultView: View {
    let title = ""
    let questions: [Question]
    let answers: [String: Option]
    let isFromTest: Bool

    @Binding var isTestActive: Bool // Controla el cierre completo del flujo del test
    @EnvironmentObject var giftManager: GiftManager
    @EnvironmentObject var profileManager: OlfactiveProfileManager
    @EnvironmentObject var familiaOlfativaManager: FamiliaOlfativaManager
    @State private var profile: String = ""
    @State private var complementaryProfile: String = ""
    @State private var suggestedPerfumes: [(perfume: Perfume, matchPercentage: Int)] = []
    @State private var isSavePopupVisible = false
    @State private var isCloseConfirmationVisible = false
    @State private var isAccordionExpanded = false
    @State private var saveName: String = ""

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Título
                            Text("Perfil Olfativo")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#2D3748"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                                .padding(.leading, 16)

                            // Perfil recomendado
                            VStack(spacing: 5) {
                                ZStack {
                                    LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    VStack(alignment: .leading, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Principal:")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color(hex: "#2D3748"))
                                                Text(profile)
                                                    .font(.headline)
                                                    .foregroundColor(Color(hex: "#4A5568"))
                                            }
                                            HStack {
                                                Text("Complementado por:")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color(hex: "#2D3748"))
                                                Text(complementaryProfile)
                                                    .font(.headline)
                                                    .foregroundColor(Color(hex: "#4A5568"))
                                            }
                                        }
                                        Text("Este perfil representa tus preferencias principales, combinado con notas complementarias.")
                                            .font(.footnote)
                                            .foregroundColor(Color(hex: "#4A5568"))
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(16)
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
                                        ForEach(suggestedPerfumes, id: \.perfume.id) { result in
                                            VStack(spacing: 8) {
                                                Image(result.perfume.image_name)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 100, height: 120)
                                                    .cornerRadius(8)

                                                Text(result.perfume.nombre)
                                                    .font(.headline)
                                                    .multilineTextAlignment(.center)

                                                Text("\(result.perfume.notas.prefix(3).joined(separator: ", "))")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color(hex: "#4A5568"))
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)

                                                Text("\(result.matchPercentage)% de coincidencia")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
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
                                    ForEach(questions.indices, id: \.self) { index in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(questions[index].text)
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "#2D3748"))
                                                .fontWeight(.semibold)
                                            Text(answers[questions[index].id]?.label ?? "Sin respuesta")
                                                .font(.body)
                                                .foregroundColor(Color(hex: "#4A5568"))

                                            if index != questions.count - 1 {
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
                            .onChange(of: isAccordionExpanded) { _, newValue in
                                if newValue {
                                    withAnimation {
                                        proxy.scrollTo("Accordion", anchor: .top)
                                    }
                                }
                            }
                        }
                    }

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
                .navigationTitle(profile)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    calculateProfilesAndSuggestions()
                }
                .sheet(isPresented: $isSavePopupVisible) {
                    VStack(spacing: 16) {
                        Text("Guardar Perfil")
                            .font(.headline)
                            .padding(.top)

                        TextField("Nombre del perfil", text: $saveName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: saveName) { oldValue, newValue in
                                if newValue.count > 18 {
                                    saveName = String(newValue.prefix(18))
                                }
                            }
                            .padding()

                        Button(action: saveProfile) {
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

    private func calculateProfilesAndSuggestions() {
        let profileResult = OlfactiveProfileHelper.calculateProfile(from: answers)
        self.profile = profileResult.profile
        self.complementaryProfile = profileResult.complementaryProfile
        self.suggestedPerfumes = OlfactiveProfileHelper.suggestPerfumes(
            for: profileResult,
            families: familiaOlfativaManager.familias
        )
    }

    private func saveProfile() {
        let perfumes = suggestedPerfumes.map { $0.perfume }
        let familiaId = perfumes.first?.familia ?? "personalizada"
        let familia = familiaOlfativaManager.getFamilia(byID: familiaId) ?? FamiliaOlfativa(
            id: "personalizada",
            nombre: "Personalizado",
            descripcion: "Perfil personalizado creado automáticamente.",
            notasClave: [],
            ingredientesAsociados: [],
            intensidadPromedio: "Media",
            estacionRecomendada: [],
            personalidadAsociada: [],
            color: "#CCCCCC"
        )

        let newProfile = OlfactiveProfile(
            name: saveName,
            perfumes: perfumes,
            familia: familia,
            description: familia.descripcion,
            icon: "icon_default"
        )

        profileManager.addProfile(newProfile)
        isTestActive = false
    }
}
