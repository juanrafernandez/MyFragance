import SwiftUI

struct AddPerfumeStep4View: View {
    @Binding var projection: Projection?
    @Binding var onboardingStep: Int

    var body: some View {
        
        Text("¿Cómo describirías la proyección de este perfume?")
            .font(.title2)
            .multilineTextAlignment(.center)
        
        VStack(alignment: .leading, spacing: 15) { // VStack para los botones con spacing
            ForEach(Projection.allCases, id: \.self) { projectionCase in
                GenericOptionButtonView<Projection>( // Usamos GenericOptionButtonView con tipo Projection
                    optionCase: projectionCase,
                    selectedOption: $projection // Pasamos el binding de projection
                ) { // Acción al pulsar el botón
                    projection = projectionCase // Actualizar la proyección seleccionada
                    onboardingStep = 5          // Ir al siguiente paso
                }
            }
        }
        .padding(.top, 15)   // Añadido padding top para separar del texto de la pregunta
        Spacer() // Empujar el contenido hacia arriba
    }
}
