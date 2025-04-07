import SwiftUI
import Kingfisher
import Combine

// MARK: - AddPerfumeInitialStepsView
struct AddPerfumeInitialStepsView: View {
    @Binding var isAddingPerfume: Bool
    @State private var selectedPerfume: Perfume? = nil
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel // YA EXISTE: EnvironmentObject
    @Environment(\.dismiss) var dismiss

    var perfumeToEdit: Perfume? = nil
    @State private var onboardingStep: Int = 1 // initialStep
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan // Default preset
    @State private var showingEvaluationOnboarding = false // State for AddPerfumeStep2View's navigationDestination


    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    switch onboardingStep {
                    case 1:
                        AddPerfumeStep1View(
                            selectedPerfume: $selectedPerfume,
                            perfumeViewModel: perfumeViewModel,
                            brandViewModel: brandViewModel, // ¡PASAR brandViewModel AQUÍ!
                            onboardingStep: $onboardingStep,
                            initialSelectedPerfume: perfumeToEdit,
                            isAddingPerfume: $isAddingPerfume,
                            showingEvaluationOnboarding: $showingEvaluationOnboarding
                        )
                    case 2:
                        AddPerfumeOnboardingView(isAddingPerfume: $isAddingPerfume, triedPerfumeRecord: nil, initialStep: 3, selectedPerfumeForEvaluation: selectedPerfume) // Case 2: AddPerfumeOnboardingView (Step 3)
                    default:
                        Text("Error: Paso desconocido")
                    }
                }
                .navigationTitle(onboardingStep == 1 ? "Añadir Perfume" : "Detalles del Perfume")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button(action: {
                    if onboardingStep == 1 {
                        dismiss()
                    } else {
                        onboardingStep = 1
                        selectedPerfume = nil
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                })
            }
        }
        .onAppear {
            if perfumeToEdit != nil {
                selectedPerfume = perfumeToEdit
                onboardingStep = 2 // Or 3 depending on desired initial step for edit
            }
        }
    }
}
