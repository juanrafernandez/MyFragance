import SwiftUI
import Combine
import FirebaseFirestore

public struct AddPerfumeOnboardingView: View {
    @Binding var isAddingPerfume: Bool
    @State private var currentStepIndex: Int = 0  // Index in the steps array

    // NUEVO: ViewModel para cargar preguntas desde Firestore
    @StateObject private var evaluationQuestionsVM = EvaluationQuestionsViewModel()

    // Respuestas de las preguntas de Firestore (duration, projection, price)
    @State private var firestoreAnswers: [String: Option] = [:]  // stepType -> Option seleccionada

    // Campos de evaluación
    @State private var impressions: String = ""
    @State private var ratingValue: Double = 0.0
    @State private var selectedOccasions: Set<Occasion> = []
    @State private var selectedSeasons: Set<Season> = []
    @State private var selectedPersonalities: Set<Personality> = []

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var triedPerfumeRecord: TriedPerfumeRecord?
    let selectedPerfumeForEvaluation: Perfume?
    let configuration: OnboardingConfiguration

    init(
        isAddingPerfume: Binding<Bool>,
        triedPerfumeRecord: TriedPerfumeRecord?,
        selectedPerfumeForEvaluation: Perfume?,
        configuration: OnboardingConfiguration
    ) {
        _isAddingPerfume = isAddingPerfume
        self.triedPerfumeRecord = triedPerfumeRecord
        self.selectedPerfumeForEvaluation = selectedPerfumeForEvaluation
        self.configuration = configuration
    }

    // MARK: - Computed Properties

    private var currentStep: OnboardingStepType {
        guard currentStepIndex < configuration.steps.count else {
            return configuration.steps.last ?? .impressionsAndRating
        }
        return configuration.steps[currentStepIndex]
    }

    private var isLastStep: Bool {
        return currentStepIndex == configuration.steps.count - 1
    }

    public var body: some View {
        ZStack {
            gradientBackground

            VStack {
                VStack {
                    progressBar
                }

                ZStack {
                    VStack {
                        stepView(for: currentStep)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    VStack {
                        Spacer()
                        if isLastStep {
                            AppButton(
                                title: triedPerfumeRecord != nil ? "Actualizar" : "Guardar",
                                action: {
                                    Task {
                                        await saveTriedPerfume()
                                    }
                                },
                                style: .accent,
                                size: .large,
                                isFullWidth: true,
                                icon: "checkmark.circle.fill"
                            )
                            .padding(.bottom)
                        }
                    }
                }
                .padding()
                .task {
                    // Cargar preguntas de evaluación desde Firestore
                    await evaluationQuestionsVM.loadEvaluationQuestions(type: .miOpinion)

                    // ✅ FIX: Pre-cargar respuestas de Firestore cuando se edita
                    if let record = triedPerfumeRecord {
                        await preloadFirestoreAnswers(from: record)
                    }
                }
                .onAppear {
                    currentStepIndex = 0
                    if let record = triedPerfumeRecord {
                        impressions = record.impressions ?? ""
                        ratingValue = record.rating ?? 0.0
                        selectedOccasions = Set((record.occasions ?? []).compactMap(Occasion.init(rawValue:)))
                        selectedSeasons = Set((record.seasons ?? []).compactMap(Season.init(rawValue:)))
                        selectedPersonalities = Set((record.personalities ?? []).compactMap(Personality.init(rawValue:)))
                    }
                }
                .navigationTitle(currentStep.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        backButton
                    }
                }
                .alert(item: $userViewModel.errorMessage) { error in
                    Alert(title: Text("Error"), message: Text(error.value), dismissButton: .default(Text("OK")))
                }
            }
        }
    }

    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#F3E9E5") ?? .gray, .white]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var progressBar: some View {
        VStack(alignment: .leading) {
            ProgressView(value: Double(currentStepIndex + 1), total: Double(configuration.totalSteps))
                .progressViewStyle(.linear)
                .tint(Color(hex: "#F6AD55") ?? .orange)
            Text("\(currentStepIndex + 1) / \(configuration.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var backButton: some View {
        Button(action: {
            if currentStepIndex > 0 {
                currentStepIndex -= 1
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }, label: {
            Image(systemName: "arrow.backward")
                .foregroundColor(.black)
        })
    }

    // MARK: - Step View Builder

    @ViewBuilder
    private func stepView(for stepType: OnboardingStepType) -> some View {
        switch stepType {
        case .duration:
            if let question = evaluationQuestionsVM.getQuestion(byStepType: "duration") {
                evaluationQuestionView(for: question, stepType: "duration")
            } else {
                // Mostrar loading o error si no hay pregunta disponible
                Text("Cargando pregunta...")
                    .foregroundColor(.secondary)
            }
        case .projection:
            if let question = evaluationQuestionsVM.getQuestion(byStepType: "projection") {
                evaluationQuestionView(for: question, stepType: "projection")
            } else {
                Text("Cargando pregunta...")
                    .foregroundColor(.secondary)
            }
        case .price:
            if let question = evaluationQuestionsVM.getQuestion(byStepType: "price") {
                evaluationQuestionView(for: question, stepType: "price")
            } else {
                Text("Cargando pregunta...")
                    .foregroundColor(.secondary)
            }
        case .occasions:
            AddPerfumeStep6View(
                selectedOccasions: $selectedOccasions,
                onNext: { goToNextStep() }
            )
        case .personalities:
            AddPerfumeStep7View(
                selectedPersonalities: $selectedPersonalities,
                onNext: { goToNextStep() }
            )
        case .seasons:
            AddPerfumeStep8View(
                selectedSeasons: $selectedSeasons,
                onNext: { goToNextStep() }
            )
        case .impressionsAndRating:
            AddPerfumeStep9View(
                impressions: $impressions,
                ratingValue: $ratingValue
            )
        }
    }

    /// Helper para mostrar pregunta de Firestore
    @ViewBuilder
    private func evaluationQuestionView(for question: Question, stepType: String) -> some View {
        EvaluationQuestionView(
            question: question,
            selectedOption: Binding(
                get: { firestoreAnswers[stepType] },
                set: { firestoreAnswers[stepType] = $0 }
            ),
            onNext: {
                goToNextStep()
            }
        )
    }

    // MARK: - Navigation

    private func goToNextStep() {
        if currentStepIndex < configuration.steps.count - 1 {
            currentStepIndex += 1
        }
    }

    /// ✅ NEW: Pre-carga las respuestas de Firestore cuando se edita un perfume probado
    private func preloadFirestoreAnswers(from record: TriedPerfumeRecord) async {
        #if DEBUG
        print("🔄 [PreloadFirestore] Cargando respuestas guardadas...")
        print("   - Duration: \(record.duration)")
        print("   - Projection: \(record.projection)")
        print("   - Price: \(record.price)")
        #endif

        // Esperar a que las preguntas estén cargadas
        guard !evaluationQuestionsVM.questions.isEmpty else {
            #if DEBUG
            print("⚠️ [PreloadFirestore] Preguntas aún no cargadas")
            #endif
            return
        }

        // Buscar y asignar duration
        if let durationQuestion = evaluationQuestionsVM.getQuestion(byStepType: "duration"),
           let selectedOption = durationQuestion.options.first(where: { $0.value == record.duration }) {
            firestoreAnswers["duration"] = selectedOption
            #if DEBUG
            print("✅ [PreloadFirestore] Duration seleccionado: \(selectedOption.label)")
            #endif
        }

        // Buscar y asignar projection
        if let projectionQuestion = evaluationQuestionsVM.getQuestion(byStepType: "projection"),
           let selectedOption = projectionQuestion.options.first(where: { $0.value == record.projection }) {
            firestoreAnswers["projection"] = selectedOption
            #if DEBUG
            print("✅ [PreloadFirestore] Projection seleccionado: \(selectedOption.label)")
            #endif
        }

        // Buscar y asignar price
        if let priceQuestion = evaluationQuestionsVM.getQuestion(byStepType: "price"),
           let selectedOption = priceQuestion.options.first(where: { $0.value == record.price }) {
            firestoreAnswers["price"] = selectedOption
            #if DEBUG
            print("✅ [PreloadFirestore] Price seleccionado: \(selectedOption.label)")
            #endif
        }
    }

    private func saveTriedPerfume() async {
        guard let userId = authViewModel.currentUser?.id else {
            #if DEBUG
            print("Error: Usuario no autenticado.")
            #endif
            userViewModel.errorMessage = IdentifiableString(value: "Debes iniciar sesión para guardar.")
            return
        }
        guard let perfume = selectedPerfumeForEvaluation else {
             #if DEBUG
             print("Error: No hay perfume seleccionado (selectedPerfumeForEvaluation es nil).")
             #endif
             userViewModel.errorMessage = IdentifiableString(value: "Error interno: No se encontró el perfume.")
             return
        }
//        guard let perfumeId = perfume.id, !perfumeId.isEmpty else {
//                    print("Error: El perfume seleccionado no tiene un ID válido (nil o vacío).")
//                    userViewModel.errorMessage = IdentifiableString(value: "Error interno: ID de perfume inválido.")
//                    return
//                }
        // Validar que se hayan respondido todas las preguntas requeridas
        guard let durationOption = firestoreAnswers["duration"] else {
            userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona una duración.")
            return
        }
        guard let projectionOption = firestoreAnswers["projection"] else {
            userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona una proyección.")
            return
        }
        guard let priceOption = firestoreAnswers["price"] else {
            userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona un rango de precio.")
            return
        }

        let durationValue = durationOption.value
        let projectionValue = projectionOption.value
        let priceValue = priceOption.value

        #if DEBUG
        print("✅ [SaveEvaluation] Guardando evaluación:")
        print("   Duration: \(durationValue) (from \(durationOption.label))")
        print("   Projection: \(projectionValue) (from \(projectionOption.label))")
        print("   Price: \(priceValue) (from \(priceOption.label))")
        print("   Rating: \(ratingValue)")
        print("   Notes: \(impressions)")
        #endif

        let occasionRawValues = selectedOccasions.map { $0.rawValue }
        let seasonRawValues = selectedSeasons.map { $0.rawValue }
        let personalityRawValues = selectedPersonalities.map { $0.rawValue }

        // ✅ FIX: Implementar edición con nuevo modelo TriedPerfume
        if let existingRecord = triedPerfumeRecord {
            #if DEBUG
            print("✅ [EditMode] Actualizando perfume probado existente")
            print("   - TriedPerfumeRecord.perfumeId: \(existingRecord.perfumeId)")
            print("   - TriedPerfumeRecord.perfumeKey: \(existingRecord.perfumeKey)")
            print("   - Perfume.key: \(perfume.key)")
            #endif

            // ✅ UNIFIED CRITERION: Usar perfumeKey (que es perfume.key = "marca_nombre")
            // existingRecord.perfumeKey ahora contiene perfume.key del perfume actual
            // Esto garantiza que siempre use el formato "marca_nombre" consistente
            let updatedTriedPerfume = TriedPerfume(
                id: existingRecord.perfumeKey,  // ✅ perfume.key (ej: "lattafa_khamrah")
                perfumeId: existingRecord.perfumeKey,  // ✅ perfume.key (ej: "lattafa_khamrah")
                rating: ratingValue,
                notes: impressions,
                triedAt: existingRecord.createdAt ?? Date(),
                updatedAt: Date(),
                userPersonalities: personalityRawValues,
                userPrice: priceValue,
                userSeasons: seasonRawValues,
                userProjection: projectionValue,
                userDuration: durationValue
            )

            #if DEBUG
            print("📝 [EditMode] TriedPerfume construido para actualización:")
            print("   - perfumeId: \(updatedTriedPerfume.perfumeId)")
            print("   - Rating: \(ratingValue)")
            print("   - Duration: \(durationValue)")
            print("   - Projection: \(projectionValue)")
            print("   - Price: \(priceValue)")
            print("   - Notes: \(impressions.prefix(50))...")
            print("🔥 [EditMode] Actualizando documento: users/{userId}/tried_perfumes/\(updatedTriedPerfume.perfumeId)")
            #endif

            await userViewModel.updateTriedPerfume(updatedTriedPerfume)

            #if DEBUG
            if userViewModel.errorMessage != nil {
                print("❌ [EditMode] Error al actualizar: \(userViewModel.errorMessage?.value ?? "desconocido")")
            } else {
                print("✅ [EditMode] Actualización completada sin errores")
            }
            #endif
        } else {
            #if DEBUG
            print("✅ [AddMode] Añadiendo nuevo perfume probado")
            print("   - Perfume.key: \(perfume.key)")
            print("   - Usando como document ID: \(perfume.key)")
            #endif

            // ✅ UNIFIED CRITERION: SIEMPRE usar perfume.key (formato "marca_nombre")
            // Esto garantiza consistencia y evita colisiones entre perfumes con mismo nombre
            // El key es el identificador único del perfume (ej: "lattafa_khamrah")
            await userViewModel.addTriedPerfume(
                perfumeId: perfume.key,  // ✅ Document ID = "marca_nombre"
                rating: ratingValue,
                userProjection: projectionValue,
                userDuration: durationValue,
                userPrice: priceValue,
                notes: impressions,
                userSeasons: seasonRawValues,
                userPersonalities: personalityRawValues
            )
        }

        if userViewModel.errorMessage == nil {
            isAddingPerfume = false
            presentationMode.wrappedValue.dismiss() // Dismiss on success
        } else {
            #if DEBUG
            print("Error saving tried perfume: \(userViewModel.errorMessage?.value ?? "Unknown error")")
            #endif
        }
    }
}
