//
//  ProfileCard.swift
//  PerfBeta
//
//  Created by ES00571759 on 13/11/23.
//

import SwiftUI

// MARK: - Tarjeta de Perfil (ProfileCard)
struct ProfileCard: View {
    let profile: OlfactiveProfile
    @ObservedObject var perfumeViewModel: PerfumeViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: 0) {

                    VStack {
                        Text("PERFIL".uppercased())
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color("textoSecundario"))

                        Text(profile.name)
                            .font(.system(size: 50, weight: .ultraLight))
                            .foregroundColor(Color("textoPrincipal"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 5)
                            .lineLimit(2)

                        Text(profile.families.prefix(3).map { $0.family }.joined(separator: ", ").capitalized)
                            .font(.system(size: 18, weight: .thin))
                            .foregroundColor(Color("textoSecundario"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()

                    VStack(alignment: .center, spacing: 0) {
                        PerfumeHorizontalListView(allPerfumes: perfumeViewModel.perfumes, cardWidth: geometry.size.width, onPerfumeTap: { perfume in })
                            .frame(height: geometry.size.height * 0.38)
                            .padding(.bottom, 1)

                        VStack {
                            HomeDidYouKnowSectionView()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 35)
                    }
                }
                .padding(.top, 24)
            }
        }
    }
}
