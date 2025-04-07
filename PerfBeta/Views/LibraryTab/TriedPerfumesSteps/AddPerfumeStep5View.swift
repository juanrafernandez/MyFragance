import SwiftUI

struct AddPerfumeStep5View: View {
    @Binding var price: Price?
    @Binding var onboardingStep: Int
    
    var body: some View {
        
        Text("¿Cuál dirías que es el rango de precio de este perfume?")
            .font(.title2)
            .multilineTextAlignment(.center)
        
        VStack(alignment: .leading, spacing: 15) { // VStack para los botones con spacing
            ForEach(Price.allCases, id: \.self) { priceCase in
                GenericOptionButtonView<Price>( // Usamos GenericOptionButtonView con tipo Price
                    optionCase: priceCase,
                    selectedOption: $price // Pasamos el binding de price
                ) { // Acción al pulsar el botón
                    price = priceCase // Actualizar el precio seleccionado
                    onboardingStep = 6      // Ir al siguiente paso
                }
            }
        }
        .padding(.top, 15)   // Añadido padding top para separar del texto de la pregunta
        Spacer() // Empujar el contenido hacia arriba
    }
}
