import SwiftUI
import Kingfisher
import Combine
import UIKit

struct AddPerfumeInitialStepsView: View {
    @Binding var isAddingPerfume: Bool
    @State private var selectedPerfume: Perfume? = nil
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Environment(\.dismiss) var dismiss

    var perfumeToEdit: Perfume? = nil
    @State private var onboardingStep: Int = 1
    // ✅ ELIMINADO: Sistema de temas personalizable
    @State private var showingEvaluationOnboarding = false

    private let recipientEmail = "tu_email_de_soporte@dominio.com" // <-- CAMBIA ESTO
    private let emailSubject = "Sugerencia de Perfume Faltante"
    private let emailBody = """
    Hola,

    Me gustaría sugerir añadir el siguiente perfume que no encontré en la app:

    Nombre del perfume:
    Marca:
    Notas (si las conoces):


    Gracias.
    """

    var body: some View {
        NavigationStack {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    switch onboardingStep {
                    case 1:
                        AddPerfumeStep1View(
                            selectedPerfume: $selectedPerfume,
                            perfumeViewModel: perfumeViewModel,
                            brandViewModel: brandViewModel,
                            onboardingStep: $onboardingStep,
                            initialSelectedPerfume: perfumeToEdit,
                            isAddingPerfume: $isAddingPerfume,
                            showingEvaluationOnboarding: $showingEvaluationOnboarding
                        )
                    case 2:
                        AddPerfumeOnboardingView(
                            isAddingPerfume: $isAddingPerfume,
                            triedPerfumeRecord: nil,
                            initialStep: 3,
                            selectedPerfumeForEvaluation: selectedPerfume
                        )
                    default:
                        Text("Error: Paso desconocido")
                    }
                }
                .navigationTitle(onboardingStep == 1 ? "Añadir Perfume" : "Detalles del Perfume")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(action: {
                        if onboardingStep == 1 {
                            dismiss()
                        } else {
                            onboardingStep = 1
                            selectedPerfume = nil
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    },
                    trailing: Button(action: sendSuggestionEmail) {
                        Image(systemName: "envelope")
                            .foregroundColor(.primary)
                    }
                )
            }
        }
        .onAppear {
            if perfumeToEdit != nil {
                selectedPerfume = perfumeToEdit
                onboardingStep = 2
            }
        }
    }

    private func sendSuggestionEmail() {
        guard let subjectEncoded = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let bodyEncoded = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let mailto = "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let mailtoUrl = URL(string: mailto) else {
            print("Error: No se pudo crear la URL mailto para sugerencia.")
            return
        }

        if UIApplication.shared.canOpenURL(mailtoUrl) {
             print("Intentando abrir URL mailto: \(mailtoUrl)")
            UIApplication.shared.open(mailtoUrl)
        } else {
            print("Error: No se puede abrir la URL mailto. ¿Mail app configurada?")
        }
    }
}
