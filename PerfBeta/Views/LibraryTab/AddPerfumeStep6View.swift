import SwiftUI

struct AddPerfumeStep6View: View {
    @Binding var selectedOccasions: Set<Occasion>
    @Binding var onboardingStep: Int

    var body: some View {
        VStack {
            Text("¿Para qué ocasión consideras que es más adecuado este perfume?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            List { // Usamos una List para la selección múltiple
                ForEach(Occasion.allCases, id: \.self) { occasion in
                    Toggle(isOn: Binding(
                        get: { selectedOccasions.contains(occasion) },
                        set: { newValue in
                            if newValue {
                                selectedOccasions.insert(occasion)
                            } else {
                                selectedOccasions.remove(occasion)
                            }
                        }
                    )) {
                        Text(occasion.displayName) // Usamos displayName para el nombre localizado
                    }
                }
            }
            .listStyle(.plain) // Opcional: ajusta el estilo de la lista
            .padding(.horizontal, 20)

            Spacer()

            Button("Siguiente") {
                onboardingStep = 7
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
    }
}
