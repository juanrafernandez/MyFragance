import SwiftUI

struct AddPerfumeStep7View: View {
    @Binding var selectedPersonalities: Set<Personality>
    let onNext: () -> Void

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("¿Qué personalidad o personalidades dirías que mejor describen este perfume?")
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Personality.allCases, id: \.self) { personalityCase in
                            MultiSelectOptionButtonView<Personality>(
                                optionCase: personalityCase,
                                selectedOptions: $selectedPersonalities
                            ) {
                                if selectedPersonalities.contains(personalityCase) {
                                    selectedPersonalities.remove(personalityCase)
                                } else {
                                    selectedPersonalities.insert(personalityCase)
                                }
                            }
                        }
                    }
                    .padding(.top, 15)

                    Button(action: {
                        onNext()
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
