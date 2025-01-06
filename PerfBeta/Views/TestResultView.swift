import SwiftUI

struct TestResultView: View {
    let profile: OlfactiveProfile
    let isFromTest: Bool

    @Binding var isTestActive: Bool
    @EnvironmentObject var giftManager: GiftManager
    @EnvironmentObject var profileManager: OlfactiveProfileManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isSavePopupVisible = false
    @State private var isAccordionExpanded = false
    @State private var saveName: String = ""
    @State private var showExitAlert = false
    @State private var selectedPerfume: Perfume?

    private let questionService = QuestionService()

    var body: some View {
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

                        // Cabecera del perfil
                        ProfileHeaderView(profile: profile)

                        // Perfumes recomendados
                        RecommendedPerfumesView(perfumes: profile.perfumes, selectedPerfume: $selectedPerfume)

                        // Resumen del test (si aplica)
                        if let questionsAndAnswers = profile.questionsAndAnswers {
                            AccordionView(isExpanded: $isAccordionExpanded) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(questionsAndAnswers, id: \.id) { qa in
                                        if let questionText = questionService.findQuestionText(by: qa.questionId),
                                           let answerText = questionService.findAnswerText(by: qa.answerId) {
                                            Text("Pregunta: \(questionText)")
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "#2D3748"))
                                                .fontWeight(.semibold)
                                            Text("Respuesta: \(answerText)")
                                                .font(.body)
                                                .foregroundColor(Color(hex: "#4A5568"))
                                        } else {
                                            Text("Datos no disponibles")
                                                .font(.footnote)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .id("AccordionSection")
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            .onChange(of: isAccordionExpanded) {
                                if isAccordionExpanded {
                                    DispatchQueue.main.async {
                                        proxy.scrollTo("AccordionSection", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }

                // Botón para guardar el perfil
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
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isFromTest {
                        Button(action: { showExitAlert = true }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                        .alert(isPresented: $showExitAlert) {
                            Alert(
                                title: Text("¿Salir sin guardar?"),
                                message: Text("Los datos no se guardarán si sales."),
                                primaryButton: .destructive(Text("Salir")) {
                                    isTestActive = false
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    } else {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.backward")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(perfume: perfume, relatedPerfumes: profile.perfumes)
            }
            .sheet(isPresented: $isSavePopupVisible) {
                SaveProfileView(
                    profile: profile,
                    saveName: $saveName,
                    isSavePopupVisible: $isSavePopupVisible,
                    isTestActive: $isTestActive
                )
            }
        }
    }
}

struct ProfileHeaderView: View {
    let profile: OlfactiveProfile

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: profile.familia.color).opacity(0.3),
                        .white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Principal: \(profile.familia.nombre)")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#2D3748"))

                    if !profile.complementaryFamilies.isEmpty {
                        Text("Complementarias: \(profile.complementaryFamilies.map { $0.nombre }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#2D3748"))
                    }

                    Text(profile.genero.capitalized)
                        .font(.footnote)
                        .foregroundColor(Color(hex: "#4A5568"))
                    
                    if let description = profile.description {
                        Text(description)
                            .font(.footnote)
                            .foregroundColor(Color(hex: "#4A5568"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}

struct PerfumeCardView: View {
    let perfume: Perfume

    var body: some View {
        VStack(spacing: 4) {
            Image(perfume.imagenURL)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 100)
                .cornerRadius(8)

            Text(perfume.nombre)
                .font(.headline)
                .foregroundColor(Color(hex: "#2D3748"))
                .multilineTextAlignment(.center)

            Text(perfume.notasPrincipales.prefix(6).joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(Color(hex: "#4A5568"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .frame(width: 120)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}

struct RecommendedPerfumesView: View {
    let perfumes: [Perfume]
    @Binding var selectedPerfume: Perfume?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Perfumes Recomendados")
                .font(.headline)
                .foregroundColor(Color(hex: "#2D3748"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(perfumes, id: \.id) { perfume in
                        Button(action: {
                            selectedPerfume = perfume
                        }) {
                            PerfumeCardView(perfume: perfume) // Usar el subcomponente
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}


struct SaveProfileView: View {
    let profile: OlfactiveProfile
    @Binding var saveName: String
    @Binding var isSavePopupVisible: Bool
    @Binding var isTestActive: Bool
    @EnvironmentObject var profileManager: OlfactiveProfileManager // Acceso directo desde el entorno

    var body: some View {
        VStack(spacing: 16) {
            Text("Guardar Perfil")
                .font(.headline)
                .padding(.top)

            TextField("Nombre del perfil", text: $saveName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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

    private func saveProfile() {
        let newProfile = OlfactiveProfile(
            name: saveName.isEmpty ? profile.name : saveName,
            genero: profile.genero,
            perfumes: profile.perfumes,
            familia: profile.familia,
            complementaryFamilies: profile.complementaryFamilies,
            description: profile.description,
            icon: profile.icon,
            questionsAndAnswers: profile.questionsAndAnswers
        )
        profileManager.addProfile(newProfile) // Usa el profileManager desde el entorno
        isTestActive = false
    }
}
