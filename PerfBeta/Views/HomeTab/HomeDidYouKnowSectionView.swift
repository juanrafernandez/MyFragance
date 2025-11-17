//
//  HomeDidYouKnowSectionView.swift
//  PerfBeta
//
//  Created by ES00571759 on 13/11/23.
//

import SwiftUI

// MARK: - Sección ¿Sabías que...? - Refined "Did You Know" (sin cambios)
struct HomeDidYouKnowSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Added spacing in VStack
            Divider()
                .frame(height: 0.5) // Thinner divider
                .overlay(Color("textoSecundario").opacity(0.3)) // Lighter divider color
                .padding(.vertical, 12) // Increased vertical padding around divider
                .padding(.horizontal, 50)

            Text("¿SABÍAS QUE...?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.bottom, 6)

            Text("La vainilla es uno de los ingredientes más caros de la perfumería, apreciada por su aroma cálido y dulce.")
                .font(.system(size: 13, weight: .thin)) // **Reduced font size to 13 for "Did you know" text**
                .foregroundColor(Color("textoSecundario")) // Use textoSecundario for subtlety
        }
    }
}
