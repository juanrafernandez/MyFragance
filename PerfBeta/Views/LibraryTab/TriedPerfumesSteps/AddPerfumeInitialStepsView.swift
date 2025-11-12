import SwiftUI
import Kingfisher
import Combine
import UIKit

struct AddPerfumeInitialStepsView: View {
    @Binding var isAddingPerfume: Bool
    @State private var selectedPerfume: Perfume? = nil
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var authViewModel: AuthViewModel  // ✅ NEW: Necesario para obtener userId
    @Environment(\.dismiss) var dismiss

    var perfumeToEdit: Perfume? = nil
    var triedPerfumeToEdit: TriedPerfume? = nil  // ✅ NEW: Para editar perfume probado
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

    /// ✅ NEW: Convierte TriedPerfume a TriedPerfumeRecord para edición
    private var triedPerfumeRecord: TriedPerfumeRecord? {
        guard let triedPerfume = triedPerfumeToEdit,
              let userId = authViewModel.currentUser?.id,
              let perfume = selectedPerfume else {
            return nil
        }

        #if DEBUG
        print("🔄 [triedPerfumeRecord] Convirtiendo para edición:")
        print("   - triedPerfume.perfumeId (document ID viejo): \(triedPerfume.perfumeId)")
        print("   - perfume.key (key actual del perfume): \(perfume.key)")
        print("   - Usando perfume.key para mantener consistencia")
        #endif

        // ✅ UNIFIED CRITERION: Usar perfume.key para que coincida con el criterio de add
        // Si el documento viejo tenía "khamrah" pero ahora queremos "lattafa_khamrah",
        // el update creará uno nuevo con el ID correcto y el viejo quedará huérfano
        return triedPerfume.toTriedPerfumeRecord(
            userId: userId,
            perfumeKey: perfume.key,  // ✅ Usar key actual del perfume
            brandId: perfume.brand
        )
    }

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
                        // ✅ FIX: Usar configuración correcta según si está editando o no
                        AddPerfumeOnboardingView(
                            isAddingPerfume: $isAddingPerfume,
                            triedPerfumeRecord: triedPerfumeRecord,
                            selectedPerfumeForEvaluation: selectedPerfume,
                            configuration: OnboardingConfiguration(context: triedPerfumeToEdit != nil ? .triedPerfumeOpinion : .fullEvaluation)
                        )
                    default:
                        Text("Error: Paso desconocido")
                    }
                }
                .navigationTitle(onboardingStep == 1 ? "Añadir Perfume" : (triedPerfumeToEdit != nil ? "Editar Evaluación" : "Detalles del Perfume"))
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
                    trailing: Group {
                        // ✅ FIX: Mostrar "Guardar" cuando está editando, envelope cuando está añadiendo
                        if onboardingStep == 1 || triedPerfumeToEdit == nil {
                            Button(action: sendSuggestionEmail) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.primary)
                            }
                        }
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
            #if DEBUG
            print("Error: No se pudo crear la URL mailto para sugerencia.")
            #endif
            return
        }

        if UIApplication.shared.canOpenURL(mailtoUrl) {
             #if DEBUG
             print("Intentando abrir URL mailto: \(mailtoUrl)")
             #endif
            UIApplication.shared.open(mailtoUrl)
        } else {
            #if DEBUG
            print("Error: No se puede abrir la URL mailto. ¿Mail app configurada?")
            #endif
        }
    }
}
