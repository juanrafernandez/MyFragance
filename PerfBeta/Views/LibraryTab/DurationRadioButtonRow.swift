//
//  DurationRadioButtonRow.swift
//  PerfBeta
//
//  Created by ES00571759 on 5/3/25.
//


import SwiftUI

// MARK: - DurationRadioButtonRow (Sin cambios)
struct DurationRadioButtonRow: View {
    let duration: Duration
    @Binding var selectedDuration: Duration?
    @Binding var onboardingStep: Int

    var body: some View {
        HStack {
            Button(action: {
                selectedDuration = self.duration
                onboardingStep += 1
            }) {
                HStack {
                    Circle()
                        .fill(selectedDuration == self.duration ? Color("PrimaryButtonColor") : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )

                    VStack(alignment: .leading) {
                        Text(duration.displayName)
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        Text(duration.description)
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