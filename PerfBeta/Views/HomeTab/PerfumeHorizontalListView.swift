//
//  PerfumeHorizontalListView.swift
//  PerfBeta
//
//  Created by ES00571759 on 13/11/23.
//

import SwiftUI

// MARK: - Horizontal Perfume List View (MODIFICADO - SIN CARRUSEL, 3 FIJOS - CENTRADO CON SPACER)
struct PerfumeHorizontalListView: View { // MODIFICADO - SIN CARRUSEL, 3 FIJOS - RENAMED to PerfumeHorizontalListView
    let allPerfumes: [Perfume]
    var cardWidth: CGFloat
    var onPerfumeTap: ((Perfume) -> Void)? = nil
    @EnvironmentObject var brandViewModel: BrandViewModel // **IMPORTANTE - RECIBIR brandViewModel del ENTORNO** <---- ADD THIS LINE

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center) {
                Text("RECOMENDADOS PARA TI".uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                Button("Ver todos") {
                    print("Ver todos button tapped!")
                }
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("champan").opacity(0.1))
                )
            }

            HStack(alignment: .top, spacing: 0) {
                Spacer()
                ForEach(allPerfumes.prefix(3), id: \.id) { perfume in
                    PerfumeCarouselItem(perfume: perfume)
                        .frame(width: cardWidth / 3)
                        .aspectRatio(0.8, contentMode: .fit)
                        .onTapGesture {
                            onPerfumeTap?(perfume)
                        }
                        .environmentObject(brandViewModel) // **IMPORTANTE - INYECTAR brandViewModel AQUÍ**  <---- ADD THIS LINE
                }
                Spacer()
            }
            .frame(width: cardWidth, alignment: .center)
        }
        .padding(.top, 15)
    }
}
