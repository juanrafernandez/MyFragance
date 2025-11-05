import SwiftUI

struct AddPerfumeStep4View: View {
    @Binding var projection: Projection?
    let onNext: () -> Void

    var body: some View {

        Text("¿Cómo describirías la proyección de este perfume?")
            .font(.title2)
            .multilineTextAlignment(.center)

        VStack(alignment: .leading, spacing: 15) {
            ForEach(Projection.allCases, id: \.self) { projectionCase in
                GenericOptionButtonView<Projection>(
                    optionCase: projectionCase,
                    selectedOption: $projection
                ) {
                    projection = projectionCase
                    onNext()
                }
            }
        }
        .padding(.top, 15)
        Spacer()
    }
}
