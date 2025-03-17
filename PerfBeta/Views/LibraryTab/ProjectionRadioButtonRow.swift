//
//  ProjectionRadioButtonRow.swift
//  PerfBeta
//
//  Created by ES00571759 on 5/3/25.
//


import SwiftUI

// MARK: - ProjectionRadioButtonRow (Sin cambios)
struct ProjectionRadioButtonRow: View {
    let projection: Projection
    @Binding var selectedProjection: Projection?
    @Binding var onboardingStep: Int

    var body: some View {
        HStack {
            Button(action: {
                selectedProjection = projection
                onboardingStep += 1
            }) {
                HStack {
                    Circle()
                        .fill(selectedProjection == projection ? Color("PrimaryButtonColor") : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )

                    VStack(alignment: .leading) {
                        Text(projection.displayName)
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        Text(projection.description)
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