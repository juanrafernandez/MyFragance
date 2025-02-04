import SwiftUI

struct SuggestionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @Binding var isTestActive: Bool
    let questions: [Question]
    let answers: [String: Option]

    @State private var profile: String
    @State private var complementaryProfile: String
    @State private var suggestedPerfumes: [Perfume] = []
    @State private var profileName: String = ""
    @State private var showSavePrompt = false

    init(isTestActive: Binding<Bool>, questions: [Question], answers: [String: Option]) {
        self._isTestActive = isTestActive
        self.questions = questions
        self.answers = answers

        let profileResult = Self.calculateProfile(from: answers)
        self._profile = State(initialValue: profileResult.profile)
        self._complementaryProfile = State(initialValue: profileResult.complementaryProfile)
    }

    var body: some View {
        VStack {
            // Título del perfil olfativo
            Text("Tu Perfil Olfativo")
                .font(.headline)
                .padding(.top)

            Text(profile)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Complementado por \(complementaryProfile)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            // Lista de perfumes sugeridos
            if suggestedPerfumes.isEmpty {
                Text("No se encontraron perfumes para tu perfil.")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(suggestedPerfumes) { perfume in
                            resultCard(for: perfume)
                        }
                    }
                }
            }

            // Botón para guardar el perfil olfativo
            Button(action: {
                showSavePrompt = true
            }) {
                Text("Guardar Perfil Olfativo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("champan"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                    isTestActive = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Guardar Perfil", isPresented: $showSavePrompt) {
            TextField("Nombre del perfil (máx. 15 caracteres)", text: $profileName)
                .onReceive(profileName.publisher.collect()) {
                    profileName = String($0.prefix(15))
                }
            Button("Guardar") {
                saveProfile()
                dismiss()
                isTestActive = false
            }
            Button("Cancelar", role: .cancel) { }
        }
        .onAppear {
            fetchSuggestedPerfumes(for: profile, complementaryProfile: complementaryProfile)
        }
    }

    private func saveProfile() {
        // Obtener la familia asociada por ID del perfil
//        let familia = familiaOlfativaViewModel.getFamilia(byID: profile) ?? Family(
//            id: UUID().uuidString, // Ajuste aquí para usar un String como id
//            key: "personalizado",
//            name: "Personalizado",
//            familyDescription: "Perfil personalizado creado automáticamente.",
//            keyNotes: [],
//            associatedIngredients: [],
//            averageIntensity: "Media",
//            recommendedSeason: [],
//            associatedPersonality: [],
//            occasion: [],
//            familyColor: "#CCCCCC"
//        )
//
//        // Crear el nuevo perfil usando los datos de la familia
//        let newProfile = OlfactiveProfile(
//            id: UUID().uuidString, // Generar un nuevo id si es necesario
//            name: profileName,
//            genero: "masculino",
//            familia: familia,
//            complementaryFamilies: [], // Complementary families pueden ajustarse después
//            descriptionProfile: familia.familyDescription,
//            icon: "icon_default",
//            questionsAndAnswers: answers.compactMap { questionID, option in
//                if let questionUUID = UUID(uuidString: questionID), let answerUUID = UUID(uuidString: option.value) {
//                    return QuestionAnswer(questionId: questionUUID, answerId: answerUUID)
//                } else {
//                    print("Error al convertir questionID o answerId a UUID. questionID: \(questionID), answerId: \(option.value)")
//                    return nil
//                }
//            }
//        )

        let newProfile = OlfactiveProfileHelper.generateProfile(from: answers)
        
        // Agregar el perfil al ViewModel
        Task {
            await olfactiveProfileViewModel.addOrUpdateProfile(newProfile)
        }
    }

    private static func calculateProfile(from answers: [String: Option]) -> (profile: String, complementaryProfile: String) {
        // Accedemos directamente a las claves de `families`
        let families = answers.values.compactMap { $0.families.keys.first }
        let profile = families.mostFrequent() ?? "Desconocido"
        let complementaryProfile = families.last ?? "Desconocido"
        return (profile, complementaryProfile)
    }

    private func fetchSuggestedPerfumes(for profile: String, complementaryProfile: String) {
        suggestedPerfumes = perfumeViewModel.perfumes.filter {
            $0.family == profile || $0.family == complementaryProfile
        }
    }

    // MARK: - Tarjeta de resultado para un perfume
    private func resultCard(for perfume: Perfume) -> some View {
        VStack {
            if let imageURL = perfume.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Image("placeholder")
                        .resizable()
                }
                .scaledToFit()
                .frame(height: 120)
                .cornerRadius(8)
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(8)
            }

            Text(perfume.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .lineLimit(1)

            Text(perfume.family.capitalized)
                .font(.system(size: 12))
                .foregroundColor(Color("textoSecundario"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

}
