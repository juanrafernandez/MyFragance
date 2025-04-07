import SwiftUI

struct AddPerfumeStep8View: View {
    @Binding var selectedSeasons: Set<Season>
    @Binding var onboardingStep: Int

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("¿En qué estación del año te gusta más usar este perfume?")
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Season.allCases, id: \.self) { seasonCase in
                            MultiSelectOptionButtonView<Season>(
                                optionCase: seasonCase,
                                selectedOptions: $selectedSeasons
                            ) {
                                if selectedSeasons.contains(seasonCase) {
                                    selectedSeasons.remove(seasonCase)
                                } else {
                                    selectedSeasons.insert(seasonCase)
                                }
                            }
                        }
                    }
                    .padding(.top, 15)

                    Button(action: {
                        onboardingStep = 9
                    }) {
                        Rectangle()
                            .fill(Color("champan"))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .cornerRadius(12)
                            .overlay(
                                Text("Continuar")
                                    .foregroundColor(.white)
                                    .padding()
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
