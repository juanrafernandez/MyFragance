import SwiftUI
import Combine

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

    let stepCount = 7
    var triedPerfumeRecord: TriedPerfumeRecord?
    let initialStep: Int
    let selectedPerfumeForEvaluation: Perfume?
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan // Default preset

    init(isAddingPerfume: Binding<Bool>, triedPerfumeRecord: TriedPerfumeRecord?, initialStep: Int, selectedPerfumeForEvaluation: Perfume?) {
        _isAddingPerfume = isAddingPerfume
        self.triedPerfumeRecord = triedPerfumeRecord
        self.initialStep = initialStep
        _onboardingStep = State(initialValue: initialStep)
        self.selectedPerfumeForEvaluation = selectedPerfumeForEvaluation
    }

    public var body: some View {
        ZStack { // Envolver en ZStack para el degradado
            // Fondo degradado
            GradientView(preset: selectedGradientPreset)
                .edgesIgnoringSafeArea(.all)

            VStack {
                VStack {
                    ProgressView("Paso \(onboardingStep - 2) de \(stepCount)", value: Double(onboardingStep - 2), total: Double(stepCount))
                        .padding(.bottom)
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)

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
                        if onboardingStep == 8 {
                            Button(action: {
                                Task {
                                    guard let perfumeId = selectedPerfumeForEvaluation?.id else {
                                        print("Error: No perfume seleccionado para evaluación")
                                        return
                                    }
                                    guard let perfumeKey = selectedPerfumeForEvaluation?.key else {
                                        print("Error: No perfume key seleccionado para evaluación")
                                        return
                                    }
                                    guard let brandId = selectedPerfumeForEvaluation?.brand else {
                                        print("Error: No brand seleccionado para evaluación")
                                        return
                                    }
                                    guard let duration = duration?.rawValue else {
                                        print("Error: No duration seleccionado")
                                        return
                                    }
                                    guard let projection = projection?.rawValue else {
                                        print("Error: No projection seleccionado")
                                        return
                                    }
                                    guard let price = price?.rawValue else {
                                        print("Error: No price seleccionado")
                                        return
                                    }
                                    // Convertir Sets de Enums a Arrays de String (rawValue) para Firestore
                                    let occasionRawValues = selectedOccasions.map { $0.rawValue }
                                    let seasonRawValues = selectedSeasons.map { $0.rawValue }
                                    let personalityRawValues = selectedPersonalities.map { $0.rawValue }
                                    
                                    let userId = "testUserId"

                                    if let recordIdToEdit = triedPerfumeRecord?.id {
                                        await userViewModel.updateTriedPerfume(
                                            userId: userId,
                                            recordId: recordIdToEdit,
                                            perfumeId: perfumeId,
                                            perfumeKey: perfumeKey,
                                            brandId: brandId,
                                            projection: projection,
                                            duration: duration,
                                            price: price,
                                            rating: ratingValue,
                                            impressions: impressions,
                                            occasions: occasionRawValues,
                                            seasons: seasonRawValues,
                                            personalities: personalityRawValues
                                        )
                                    } else {
                                        await userViewModel.addTriedPerfume(
                                            userId: userId,
                                            perfumeId: perfumeId,
                                            perfumeKey: perfumeKey,
                                            brandId: brandId,
                                            projection: projection,
                                            duration: duration,
                                            price: price,
                                            rating: ratingValue,
                                            impressions: impressions,
                                            occasions: occasionRawValues,
                                            seasons: seasonRawValues,
                                            personalities: personalityRawValues
                                        )
                                    }

                                    if userViewModel.errorMessage == nil {
                                        isAddingPerfume = false
                                    } else {
                                        print("Error saving tried perfume: \(userViewModel.errorMessage?.value ?? "Unknown error")")
                                    }
                                }
                            }, label: {
                                Text(triedPerfumeRecord != nil ? "Actualizar" : "Guardar")
                            })
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom)
                        }
                    }
                }
                .padding()
                .onAppear {
                    onboardingStep = initialStep
                }
                .navigationTitle(navigationTitleForStep(onboardingStep))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(leading:
                    Button(action: {
                        if onboardingStep > 3 {
                            onboardingStep -= 1
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                    }
                )
                .alert(item: $userViewModel.errorMessage) { error in
                    Alert(title: Text("Error"), message: Text(error.value), dismissButton: .default(Text("OK")))
                }
            }
        }
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
}
