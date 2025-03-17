//
//  AddPerfumeStep4View.swift
//  PerfBeta
//
//  Created by ES00571759 on 5/3/25.
//


import SwiftUI

// MARK: - AddPerfumeStep4View (Sin cambios)
struct AddPerfumeStep5View: View {
    @Binding var price: Price?
    @Binding var onboardingStep: Int

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                ForEach(Price.allCases, id: \.self) { priceCase in
                    PriceRadioButtonRow(price: priceCase, selectedPrice: $price, onboardingStep: $onboardingStep)
                }
            }
            .frame(height: geometry.size.height, alignment: .top)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}
