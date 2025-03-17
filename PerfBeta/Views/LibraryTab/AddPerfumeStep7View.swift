//
//  AddPerfumeStep7View.swift
//  PerfBeta
//
//  Created by ES00571759 on 17/3/25.
//


import SwiftUI

struct AddPerfumeStep7View: View {
    @Binding var selectedPersonalities: Set<Personality> // Set para selección múltiple de personalidades
    @Binding var onboardingStep: Int

    var body: some View {
        VStack {
            Text("¿Qué personalidad o personalidades dirías que mejor describen este perfume?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            List { // List para selección múltiple
                ForEach(Personality.allCases, id: \.self) { personality in
                    Toggle(isOn: Binding(
                        get: { selectedPersonalities.contains(personality) },
                        set: { newValue in
                            if newValue {
                                selectedPersonalities.insert(personality)
                            } else {
                                selectedPersonalities.remove(personality)
                            }
                        }
                    )) {
                        Text(personality.displayName) // Usamos displayName para nombre localizado
                    }
                }
            }
            .listStyle(.plain) // Opcional: ajusta el estilo de la lista
            .padding(.horizontal, 20)

            Spacer()

            Button("Siguiente") {
                onboardingStep = 8 // Ahora el paso de Estación es el 8
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
    }
}

struct AddPerfumeStep7View_Previews: PreviewProvider {
    static var previews: some View {
        AddPerfumeStep7View(selectedPersonalities: .constant([.romantic, .elegant]), onboardingStep: .constant(7)) // Ejemplo con selección inicial
    }
}