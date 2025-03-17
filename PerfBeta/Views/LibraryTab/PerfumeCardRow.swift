//
//  PerfumeCardRow.swift
//  PerfBeta
//
//  Created by ES00571759 on 5/3/25.
//


import SwiftUI

// MARK: - PerfumeCardRow (Sin cambios)
struct PerfumeCardRow: View {
    let perfume: Perfume

    var body: some View {
        HStack {
            Image(perfume.imageURL ?? "givenchy_gentleman_Intense")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(perfume.name)
                    .font(.headline)
                    .foregroundColor(Color("textoPrincipal"))
                Text(perfume.brand)
                    .font(.subheadline)
                    .foregroundColor(Color("textoSecundario"))
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
