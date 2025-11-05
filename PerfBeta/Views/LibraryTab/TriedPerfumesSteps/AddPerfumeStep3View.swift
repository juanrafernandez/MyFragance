import SwiftUI

struct AddPerfumeStep3View: View {
    @Binding var duration: Duration?
    let onNext: () -> Void

    var body: some View {

        Text("¿Cuánto dura este perfume en tu piel aproximadamente?")
            .font(.title2)
            .multilineTextAlignment(.center)

        VStack(alignment: .leading, spacing: 15) {
            ForEach(Duration.allCases, id: \.self) { durationCase in
                GenericOptionButtonView<Duration>(
                    optionCase: durationCase,
                    selectedOption: $duration
                ) {
                    duration = durationCase
                    onNext()
                }
            }
        }
        .padding(.top, 15)
        Spacer()
    }
}
