import SwiftUI
import Combine
import FirebaseFirestore

public struct AddPerfumeOnboardingView: View {
    @Binding var isAddingPerfume: Bool
    @State private var onboardingStep: Int
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

    let initialStepsCount = 2
    let stepCount = 7
    var triedPerfumeRecord: TriedPerfumeRecord?
    let initialStep: Int
    let selectedPerfumeForEvaluation: Perfume?
    // ✅ ELIMINADO: Sistema de temas personalizable

    init(isAddingPerfume: Binding<Bool>, triedPerfumeRecord: TriedPerfumeRecord?, initialStep: Int, selectedPerfumeForEvaluation: Perfume?) {
        _isAddingPerfume = isAddingPerfume
        self.triedPerfumeRecord = triedPerfumeRecord
        self.initialStep = initialStep
        _onboardingStep = State(initialValue: initialStep)
        self.selectedPerfumeForEvaluation = selectedPerfumeForEvaluation
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
                        switch onboardingStep {
                        case 3:
                            AddPerfumeStep3View(duration: $duration, onboardingStep: $onboardingStep)
                        case 4:
                            AddPerfumeStep4View(projection: $projection, onboardingStep: $onboardingStep)
                        case 5:
                            AddPerfumeStep5View(price: $price, onboardingStep: $onboardingStep)
                        case 6:
                            AddPerfumeStep6View(selectedOccasions: $selectedOccasions, onboardingStep: $onboardingStep)
                        case 7:
                            AddPerfumeStep7View(selectedPersonalities: $selectedPersonalities, onboardingStep: $onboardingStep)
                        case 8:
                            AddPerfumeStep8View(selectedSeasons: $selectedSeasons, onboardingStep: $onboardingStep)
                        case 9:
                            AddPerfumeStep9View(impressions: $impressions, ratingValue: $ratingValue)
                        default:
                            Text("Error: Paso desconocido")
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    VStack {
                        Spacer()
                        if onboardingStep == 9 {
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
                    onboardingStep = initialStep
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
                .navigationTitle(navigationTitleForStep(onboardingStep))
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
            ProgressView(value: Double(onboardingStep - initialStepsCount), total: Double(stepCount))
                .progressViewStyle(.linear)
                .tint(Color(hex: "#F6AD55") ?? .orange)
            Text("\(onboardingStep - initialStepsCount) / \(stepCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var backButton: some View {
        Button(action: {
            if onboardingStep > 3 {
                onboardingStep -= 1
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }, label: {
            Image(systemName: "arrow.backward")
                .foregroundColor(.black)
        })
    }

    private func navigationTitleForStep(_ step: Int) -> String {
        switch step {
        case 3: return "Duración"
        case 4: return "Proyección"
        case 5: return "Precio"
        case 6: return "Ocasión"
        case 7: return "Personalidad"
        case 8: return "Estación"
        case 9: return "Impresiones y Valoración"
        default: return ""
        }
    }

    private func saveTriedPerfume() async {
        guard let userId = authViewModel.currentUser?.id else {
            print("Error: Usuario no autenticado.")
            userViewModel.errorMessage = IdentifiableString(value: "Debes iniciar sesión para guardar.")
            return
        }
        guard let perfume = selectedPerfumeForEvaluation else {
             print("Error: No hay perfume seleccionado (selectedPerfumeForEvaluation es nil).")
             userViewModel.errorMessage = IdentifiableString(value: "Error interno: No se encontró el perfume.")
             return
        }
//        guard let perfumeId = perfume.id, !perfumeId.isEmpty else {
//                    print("Error: El perfume seleccionado no tiene un ID válido (nil o vacío).")
//                    userViewModel.errorMessage = IdentifiableString(value: "Error interno: ID de perfume inválido.")
//                    return
//                }
        guard let durationValue = duration?.rawValue else {
            print("Error: No duration seleccionado")
             userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona una duración.")
            return
        }
        guard let projectionValue = projection?.rawValue else {
            print("Error: No projection seleccionado")
             userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona una proyección.")
            return
        }
        guard let priceValue = price?.rawValue else {
            print("Error: No price seleccionado")
             userViewModel.errorMessage = IdentifiableString(value: "Por favor, selecciona un rango de precio.")
            return
        }

        let occasionRawValues = selectedOccasions.map { $0.rawValue }
        let seasonRawValues = selectedSeasons.map { $0.rawValue }
        let personalityRawValues = selectedPersonalities.map { $0.rawValue }

        // TODO: Reimplement edit functionality with new TriedPerfume model
        if triedPerfumeRecord != nil {
            print("⚠️ EDIT MODE TEMPORARILY DISABLED - needs refactor to TriedPerfume")
            userViewModel.errorMessage = IdentifiableString(value: "Edición temporalmente deshabilitada")
            return
        }

        // ✅ REFACTOR: Nueva API para añadir (use key for lookups)
        await userViewModel.addTriedPerfume(
            perfumeId: perfume.key,
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
            print("Error saving tried perfume: \(userViewModel.errorMessage?.value ?? "Unknown error")")
        }
    }
}
