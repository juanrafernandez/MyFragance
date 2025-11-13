import SwiftUI

struct GiftResultsView: View {
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showingSaveDialog = false
    @State private var profileNickname = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header con título
                headerSection

                // Recomendaciones
                recommendationsSection

                // Botón para guardar perfil
                saveProfileButton

                // Botón para nueva búsqueda
                newSearchButton
            }
            .padding(.horizontal, 25)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingSaveDialog) {
            saveProfileDialog
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("champan"))

            Text("Recomendaciones de Regalo")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)

            Text("Hemos encontrado \(giftRecommendationViewModel.recommendations.count) perfumes perfectos")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(giftRecommendationViewModel.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                recommendationCard(recommendation: recommendation, rank: index + 1)
            }
        }
    }

    private func recommendationCard(recommendation: GiftRecommendation, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ranking badge
            HStack {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(rankColor(for: rank))
                    )

                Spacer()

                // Confidence indicator
                confidenceBadge(recommendation.confidenceLevel)
            }

            // Perfume info (buscar en el catálogo)
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: recommendation.perfumeKey) {
                HStack(spacing: 12) {
                    // Imagen del perfume (si existe)
                    if let imageURL = perfume.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 60, height: 80)
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(perfume.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))

                        Text(perfume.brand)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("textoSecundario"))

                        // Score
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color("champan"))
                            Text(String(format: "%.0f%%", recommendation.score))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color("champan"))
                        }
                    }

                    Spacer()
                }
            } else {
                // Fallback si no se encuentra el perfume
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.perfumeKey)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("textoPrincipal"))

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color("champan"))
                        Text(String(format: "%.0f%%", recommendation.score))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color("champan"))
                    }
                }
            }

            // Razón de la recomendación
            Text(recommendation.reason)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color("textoSecundario"))
                .fixedSize(horizontal: false, vertical: true)

            // Match factors
            if !recommendation.matchFactors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Factores de coincidencia:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("textoPrincipal"))

                    ForEach(recommendation.matchFactors, id: \.factor) { factor in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color("champan"))
                                .frame(width: 4, height: 4)

                            Text("\(factor.factor): ")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color("textoPrincipal"))
                            +
                            Text(factor.description)
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(Color("textoSecundario"))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor(for: rank).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Confidence Badge

    private func confidenceBadge(_ level: ConfidenceLevel) -> some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: 10))
            Text(level.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(confidenceColor(level))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(confidenceColor(level).opacity(0.15))
        )
    }

    // MARK: - Save Profile Button

    private var saveProfileButton: some View {
        Button(action: {
            showingSaveDialog = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Guardar Perfil de Regalo")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("champan"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.top, 10)
    }

    // MARK: - New Search Button

    private var newSearchButton: some View {
        Button(action: {
            Task {
                await giftRecommendationViewModel.startNewFlow()
            }
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Nueva Búsqueda")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.1))
            .foregroundColor(Color("textoPrincipal"))
            .cornerRadius(12)
        }
    }

    // MARK: - Save Profile Dialog

    private var saveProfileDialog: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text("Guardar Perfil")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    Text("Dale un nombre a este perfil para encontrarlo fácilmente después")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .multilineTextAlignment(.center)

                    TextField("Ej: Mamá, Mejor amigo, Compañero trabajo...", text: $profileNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 8)

                    Button(action: {
                        Task {
                            await giftRecommendationViewModel.saveProfile(nickname: profileNickname)
                            showingSaveDialog = false
                            profileNickname = ""
                        }
                    }) {
                        Text("Guardar")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                profileNickname.isEmpty
                                    ? Color.gray.opacity(0.3)
                                    : Color("champan")
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(profileNickname.isEmpty)

                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.top, 40)
            }
            .navigationBarItems(
                trailing: Button("Cancelar") {
                    showingSaveDialog = false
                    profileNickname = ""
                }
                .foregroundColor(Color("textoPrincipal"))
            )
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helper Methods

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1:
            return Color("champan")
        case 2:
            return Color.blue.opacity(0.8)
        case 3:
            return Color.green.opacity(0.8)
        default:
            return Color.gray
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high:
            return Color.green
        case .medium:
            return Color.orange
        case .low:
            return Color.red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        GiftResultsView()
            .environmentObject(GiftRecommendationViewModel(
                authService: DependencyContainer.shared.authService
            ))
            .environmentObject(PerfumeViewModel(
                perfumeService: DependencyContainer.shared.perfumeService
            ))
    }
}
