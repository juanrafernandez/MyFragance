//
//  PerfumeCarouselItem.swift
//  PerfBeta
//
//  Created by ES00571759 on 13/11/23.
//

import SwiftUI

struct PerfumeCarouselItem: View {
    let perfume: Perfume
    @EnvironmentObject var brandViewModel: BrandViewModel // <-- Make sure this line IS present

    var body: some View {
        VStack(alignment: .center, spacing: 0) { // **MODIFICADO - spacing a 0**
            ZStack(alignment: .topTrailing) { // ZStack para superponer el porcentaje
                Image("perfume_bottle_placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 100)
                    .cornerRadius(12)

                Text("95%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.green)
                    .cornerRadius(6)
            }
            .aspectRatio(1, contentMode: .fit)

            Text(perfume.name)
                .font(.system(size: 12, weight: .thin))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 6)

            let brandKey = perfume.brand
            if let brand = brandViewModel.getBrand(byKey: brandKey) {
                Text(brand.name.capitalized)
                    .font(.system(size: 10, weight: .thin))
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 3)
            } else {
                Text("Brand N/A")
                    .font(.system(size: 9, weight: .thin))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 3)
            }
        }
    }
}
