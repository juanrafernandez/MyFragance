import SwiftUI
import Combine
import FirebaseFirestore

public struct AddPerfumeOnboardingView: View {
    @Binding var isAddingPerfume: Bool
    @State private var currentStepIndex: Int = 0  // Index in the steps array
    @State private var duration: Duration? = nil
    @State private var projection: Projection? = nil
    @State private var price: Price? = nil
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
                .onAppear {
                    currentStepIndex = 0
                    if let record = triedPerfumeRecord {
                        duration = Duration(rawValue: record.duration)
                        projection = Projection(rawValue: record.projection)
                        price = Price(rawValue: record.price ?? "")
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
            AddPerfumeStep3View(
                duration: $duration,
                onNext: { goToNextStep() }
            )
        case .projection:
            AddPerfumeStep4View(
                projection: $projection,
                onNext: { goToNextStep() }
            )
        case .price:
            AddPerfumeStep5View(
                price: $price,
                onNext: { goToNextStep() }
            )
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

    // MARK: - Navigation

    private func goToNextStep() {
        if currentStepIndex < configuration.steps.count - 1 {
            currentStepIndex += 1
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
        guard let durationValue = duration?.rawValue else {
            #if DEBUG
            print("Error: No duration seleccionado")
            #endif
             userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona una duración.")
            return
        }
        guard let projectionValue = projection?.rawValue else {
            #if DEBUG
            print("Error: No projection seleccionado")
            #endif
             userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona una proyección.")
            return
        }
        guard let priceValue = price?.rawValue else {
            #if DEBUG
            print("Error: No price seleccionado")
            #endif
             userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona un rango de precio.")
            return
        }

        let occasionRawValues = selectedOccasions.map { $0.rawValue }
        let seasonRawValues = selectedSeasons.map { $0.rawValue }
        let personalityRawValues = selectedPersonalities.map { $0.rawValue }

        // TODO: Reimplement edit functionality with new TriedPerfume model
        if triedPerfumeRecord != nil {
            #if DEBUG
            print("⚠️ EDIT MODE TEMPORARILY DISABLED - needs refactor to TriedPerfume")
            #endif
            userViewModel.errorMessage = IdentifiableString(value: "Edición temporalmente deshabilitada")
            return
        }

        // ✅ Use document ID (not key) for cache consistency
        await userViewModel.addTriedPerfume(
            perfumeId: perfume.id,
            rating: ratingValue,
            userProjection: projectionValue,
            userDuration: durationValue,
            userPrice: priceValue,
            notes: impressions,
            userSeasons: seasonRawValues,
            userPersonalities: personalityRawValues
        )

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
