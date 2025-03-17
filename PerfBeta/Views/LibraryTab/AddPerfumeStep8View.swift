//
//  AddPerfumeStep7View.swift
//  PerfBeta
//
//  Created by ES00571759 on 17/3/25.
//


import SwiftUI

struct AddPerfumeStep8View: View {
    @Binding var selectedSeasons: Set<Season>
    @Binding var onboardingStep: Int

    var body: some View {
        VStack {
            Text("¿En qué estación del año te gusta más usar este perfume?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            List { // Usamos una List para la selección múltiple
                ForEach(Season.allCases, id: \.self) { season in
                    Toggle(isOn: Binding(
                        get: { selectedSeasons.contains(season) },
                        set: { newValue in
                            if newValue {
                                selectedSeasons.insert(season)
                            } else {
                                selectedSeasons.remove(season)
                            }
                        }
                    )) {
                        Text(season.displayName) // Usamos displayName para el nombre localizado
                    }
                }
            }
            .listStyle(.plain) // Opcional: ajusta el estilo de la lista
            .padding(.horizontal, 20)

            Spacer()

            Button("Siguiente") {
                onboardingStep = 8 // El paso 6 original ahora es el 8
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .padding()
    }
}
