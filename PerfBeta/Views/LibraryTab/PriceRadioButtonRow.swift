//
//  PriceRadioButtonRow.swift
//  PerfBeta
//
//  Created by ES00571759 on 5/3/25.
//


import SwiftUI

// MARK: - PriceRadioButtonRow (Sin cambios)
struct PriceRadioButtonRow: View {
    let price: Price
    @Binding var selectedPrice: Price?
    @Binding var onboardingStep: Int

    var body: some View {
        HStack {
            Button(action: {
                selectedPrice = price
                onboardingStep += 1
            }) {
                HStack {
                    Circle()
                        .fill(selectedPrice == price ? Color("PrimaryButtonColor") : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )

                    VStack(alignment: .leading) {
                        Text(price.displayName)
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        Text(price.description)
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}