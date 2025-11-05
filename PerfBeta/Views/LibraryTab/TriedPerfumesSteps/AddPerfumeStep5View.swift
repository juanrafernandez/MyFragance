import SwiftUI

struct AddPerfumeStep5View: View {
    @Binding var price: Price?
    let onNext: () -> Void

    var body: some View {

        Text("¿Cuál dirías que es el rango de precio de este perfume?")
            .font(.title2)
            .multilineTextAlignment(.center)

        VStack(alignment: .leading, spacing: 15) {
            ForEach(Price.allCases, id: \.self) { priceCase in
                GenericOptionButtonView<Price>(
                    optionCase: priceCase,
                    selectedOption: $price
                ) {
                    price = priceCase
                    onNext()
                }
            }
        }
        .padding(.top, 15)
        Spacer()
    }
}
