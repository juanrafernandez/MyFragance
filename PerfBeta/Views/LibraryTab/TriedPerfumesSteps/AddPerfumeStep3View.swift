import SwiftUI

struct AddPerfumeStep3View: View {
    @Binding var duration: Duration?
    @Binding var onboardingStep: Int
    
    var body: some View {
        
        Text("¿Cuánto dura este perfume en tu piel aproximadamente?")
            .font(.title2)
            .multilineTextAlignment(.center)
        
        VStack(alignment: .leading, spacing: 15) {
            ForEach(Duration.allCases, id: \.self) { durationCase in
                GenericOptionButtonView<Duration>( // Usamos GenericOptionButtonView con tipo Duration
                    optionCase: durationCase,
                    selectedOption: $duration // Pasamos el binding de duration
                ) {
                    duration = durationCase
                    onboardingStep = 4
                }
            }
        }
        .padding(.top, 15)
        Spacer()
    }
    
}
