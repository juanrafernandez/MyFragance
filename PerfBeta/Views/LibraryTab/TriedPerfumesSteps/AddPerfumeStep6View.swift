import SwiftUI

struct AddPerfumeStep6View: View {
    @Binding var selectedOccasions: Set<Occasion>
    let onNext: () -> Void

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("¿Para qué ocasión consideras que es más adecuado este perfume?")
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Occasion.allCases, id: \.self) { occasionCase in
                            MultiSelectOptionButtonView<Occasion>(
                                optionCase: occasionCase,
                                selectedOptions: $selectedOccasions
                            ) {
                                if selectedOccasions.contains(occasionCase) {
                                    selectedOccasions.remove(occasionCase)
                                } else {
                                    selectedOccasions.insert(occasionCase)
                                }
                            }
                        }
                    }
                    .padding(.top, 15)

                    Button(action: {
                        onNext()
                    }) {
                        Rectangle()
                            .fill(AppColor.brandAccent)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .cornerRadius(12)
                            .overlay(
                                Text("Continuar")
                                    .foregroundColor(.white)
                                    .padding()
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, AppSpacing.screenVertical)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
