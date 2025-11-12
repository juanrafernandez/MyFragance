import SwiftUI

/// Vista genérica para mostrar una pregunta de evaluación cargada desde Firestore
/// Reemplaza a AddPerfumeStep3View, Step4View, Step5View para preguntas dinámicas
struct EvaluationQuestionView: View {
    let question: Question
    @Binding var selectedOption: Option?
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Pregunta
            Text(question.text)
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // Opciones
            VStack(alignment: .leading, spacing: 15) {
                ForEach(question.options, id: \.id) { option in
                    FirestoreOptionButtonView(
                        option: option,
                        selectedOption: $selectedOption
                    ) {
                        selectedOption = option
                        onNext()
                    }
                }
            }
            .padding(.top, 15)

            Spacer()
        }
    }
}

/// Vista preview para desarrollo
struct EvaluationQuestionView_Previews: PreviewProvider {
    @State static var selectedOption: Option? = nil

    static var previews: some View {
        EvaluationQuestionView(
            question: Question(
                id: "eval_duration_001",
                key: "eval_duration",
                questionType: "mi_opinion",
                order: 1,
                category: "evaluation",
                text: "¿Cuánto tiempo duró el perfume en tu piel?",
                stepType: "duration",
                options: [
                    Option(
                        id: "duration_short",
                        label: "Corta",
                        value: "short",
                        description: "1-3 horas",
                        image_asset: "duration_short",
                        families: [:]
                    ),
                    Option(
                        id: "duration_moderate",
                        label: "Moderada",
                        value: "moderate",
                        description: "3-6 horas",
                        image_asset: "duration_moderate",
                        families: [:]
                    )
                ]
            ),
            selectedOption: $selectedOption,
            onNext: {
                print("Next tapped")
            }
        )
    }
}
