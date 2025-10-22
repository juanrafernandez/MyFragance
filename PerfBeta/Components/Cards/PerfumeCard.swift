//
//  PerfumeCard.swift
//  PerfBeta
//
//  Componente unificado para mostrar perfumes en diferentes contextos
//  Reemplaza: PerfumeCardView, PerfumeCarouselItem, GenericPerfumeRowView
//

import SwiftUI
import Kingfisher

// MARK: - PerfumeCard Component

struct PerfumeCard: View {
    // MARK: - Required Data
    let perfume: Perfume
    let brandName: String?

    // MARK: - Configuration
    let style: CardStyle
    let size: CardSize

    // MARK: - Optional Display Control
    var showsFamily: Bool = false
    var showsRating: Bool = true
    var showsNotes: Bool = false
    var showsPrice: Bool = false

    // MARK: - Optional Data (for specific contexts)
    var score: Double? = nil  // For recommendation scores (0-100)
    var personalRating: Double? = nil  // For tried perfumes (0-10)

    // MARK: - Interaction
    let onTap: () -> Void
    var onFavorite: (() -> Void)? = nil

    // MARK: - Body
    var body: some View {
        Group {
            switch style {
            case .compact:
                compactLayout
            case .carousel:
                carouselLayout
            case .row:
                rowLayout
            case .detailed:
                detailedLayout
            }
        }
        .onTapGesture {
            onTap()
        }
    }

    // MARK: - Compact Layout (Grid cards - Vertical)
    private var compactLayout: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: AppSpacing.spacing8) {
                // Perfume Image
                perfumeImage
                    .frame(height: size.imageHeight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .cornerRadius(AppCornerRadius.small)

                // Text Group
                VStack(spacing: AppSpacing.spacing4) {
                    // Brand Name
                    if let brand = brandName {
                        Text(brand)
                            .font(AppTypography.captionEmphasis)
                            .foregroundColor(AppColor.textSecondary)
                            .lineLimit(1)
                    }

                    // Perfume Name
                    Text(perfume.name)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(1)

                    // Family (optional)
                    if showsFamily {
                        Text(perfume.family.capitalized)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColor.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: size.cardWidth)
            .padding(AppSpacing.spacing12)
            .background(AppColor.surfaceCard)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(AppShadow.small)

            // Badge (Score or Rating)
            badgeView
                .offset(x: -AppSpacing.spacing8, y: AppSpacing.spacing8)

            // Favorite Button (optional)
            if let onFavorite = onFavorite {
                favoriteButton(action: onFavorite)
            }
        }
        .frame(width: size.cardWidth)
    }

    // MARK: - Carousel Layout (Horizontal scroll - Vertical compact)
    private var carouselLayout: some View {
        VStack(alignment: .center, spacing: AppSpacing.spacing8) {
            ZStack(alignment: .topTrailing) {
                // Perfume Image
                perfumeImage
                    .frame(width: size.imageHeight, height: size.imageHeight * 1.1)
                    .cornerRadius(AppCornerRadius.medium)

                // Badge (Score)
                badgeView
                    .offset(x: -AppSpacing.spacing4, y: AppSpacing.spacing4)
            }

            // Perfume Name
            Text(perfume.name)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, AppSpacing.spacing4)

            // Brand Name
            if let brand = brandName {
                Text(brand.capitalized)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.top, AppSpacing.spacing2)
            }
        }
        .frame(width: size.cardWidth)
    }

    // MARK: - Row Layout (Horizontal list item)
    private var rowLayout: some View {
        HStack(spacing: AppSpacing.spacing16) {
            // Perfume Image (square)
            perfumeImage
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
                .clipped()

            // Text Content
            VStack(alignment: .leading, spacing: AppSpacing.spacing4) {
                // Perfume Name
                Text(perfume.name)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(2)

                // Brand Name
                if let brand = brandName {
                    Text(brand)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Rating (Personal or General)
            if showsRating {
                if let pRating = personalRating {
                    // Personal Rating (heart)
                    HStack(spacing: AppSpacing.spacing4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(AppColor.feedbackError)
                            .font(AppTypography.caption)
                        Text(String(format: "%.1f", pRating))
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColor.textPrimary)
                    }
                } else if let gRating = perfume.popularity {
                    // General Rating (star)
                    HStack(spacing: AppSpacing.spacing4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppColor.ratingFill)
                            .font(AppTypography.caption)
                        Text(String(format: "%.1f", gRating))
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColor.textPrimary)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.spacing12)
        .background(Color.clear)
    }

    // MARK: - Detailed Layout (Full info card)
    private var detailedLayout: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing12) {
            HStack(spacing: AppSpacing.spacing16) {
                // Perfume Image
                perfumeImage
                    .frame(width: 80, height: 100)
                    .cornerRadius(AppCornerRadius.medium)

                // Text Content
                VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
                    // Brand Name
                    if let brand = brandName {
                        Text(brand.uppercased())
                            .font(AppTypography.overline)
                            .foregroundColor(AppColor.textTertiary)
                    }

                    // Perfume Name
                    Text(perfume.name)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(2)

                    // Family
                    if showsFamily {
                        HStack(spacing: AppSpacing.spacing4) {
                            Image(systemName: "leaf.fill")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColor.iconTertiary)
                            Text(perfume.family.capitalized)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColor.textSecondary)
                        }
                    }

                    // Rating
                    if showsRating {
                        ratingStars
                    }
                }

                Spacer()

                // Favorite Button
                if let action = onFavorite {
                    Button {
                        action()
                    } label: {
                        Image(systemName: "heart")
                            .foregroundColor(AppColor.iconSecondary)
                            .font(AppTypography.titleMedium)
                    }
                }
            }

            // Notes (if enabled)
            if showsNotes, let topNotes = perfume.topNotes, !topNotes.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.spacing4) {
                    Text("Notas principales")
                        .font(AppTypography.captionEmphasis)
                        .foregroundColor(AppColor.textTertiary)

                    Text(topNotes.prefix(3).joined(separator: ", "))
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                }
            }

            // Price (if enabled)
            if showsPrice, let priceValue = perfume.price {
                HStack {
                    Image(systemName: "eurosign.circle.fill")
                        .foregroundColor(AppColor.accentGold)
                        .font(AppTypography.caption)
                    Text(Price(rawValue: priceValue)?.displayName ?? priceValue)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
        }
        .padding(AppSpacing.spacing16)
        .background(AppColor.surfaceCard)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(AppShadow.small)
    }

    // MARK: - Shared Components

    private var perfumeImage: some View {
        KFImage(perfume.imageURL.flatMap { URL(string: $0) })
            .placeholder {
                ZStack {
                    AppColor.backgroundSecondary
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(AppColor.iconTertiary)
                }
            }
            .resizable()
            .scaledToFit()
    }

    @ViewBuilder
    private var badgeView: some View {
        if let scoreValue = score {
            // Score Badge (percentage - for recommendations)
            HStack(spacing: AppSpacing.spacing2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundColor(AppColor.feedbackSuccess)
                Text(String(format: "%.0f%%", scoreValue))
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
            }
            .padding(.horizontal, AppSpacing.spacing8)
            .padding(.vertical, AppSpacing.spacing4)
            .background(AppColor.surfaceElevated.opacity(0.95))
            .cornerRadius(AppCornerRadius.small)
            .shadow(AppShadow.small)
        } else if showsRating, let popularity = perfume.popularity {
            // Popularity Badge (star rating)
            HStack(spacing: AppSpacing.spacing2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(AppColor.ratingFill)
                Text(String(format: "%.1f", popularity))
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppColor.textPrimary)
            }
            .padding(.horizontal, AppSpacing.spacing8)
            .padding(.vertical, AppSpacing.spacing4)
            .background(AppColor.surfaceElevated.opacity(0.95))
            .cornerRadius(AppCornerRadius.small)
            .shadow(AppShadow.small)
        }
    }

    private func favoriteButton(action: @escaping () -> Void) -> some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    action()
                } label: {
                    Image(systemName: "heart")
                        .foregroundColor(AppColor.iconSecondary)
                        .font(AppTypography.titleSmall)
                        .padding(AppSpacing.spacing8)
                        .background(AppColor.surfaceOverlay)
                        .clipShape(Circle())
                        .shadow(AppShadow.small)
                }
                .padding(AppSpacing.spacing8)
            }
            Spacer()
        }
    }

    private var ratingStars: some View {
        HStack(spacing: AppSpacing.spacing2) {
            ForEach(0..<5) { index in
                Image(systemName: index < Int(perfume.popularity ?? 0) ? "star.fill" : "star")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.ratingFill)
            }

            if let popularity = perfume.popularity {
                Text(String(format: "%.1f", popularity))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColor.textSecondary)
            }
        }
    }
}

// MARK: - Supporting Types

extension PerfumeCard {
    enum CardStyle {
        case compact    // Minimal, for grids (replaces PerfumeCardView)
        case carousel   // For horizontal scrolling (replaces PerfumeCarouselItem)
        case row        // Horizontal list item (replaces GenericPerfumeRowView)
        case detailed   // Full info, for search/detailed lists
    }

    enum CardSize {
        case small      // 90pt image
        case medium     // 120pt image
        case large      // 160pt image

        var imageHeight: CGFloat {
            switch self {
            case .small: return 90
            case .medium: return 120
            case .large: return 160
            }
        }

        var cardWidth: CGFloat? {
            switch self {
            case .small: return 100
            case .medium: return 140
            case .large: return 180
            }
        }
    }
}

// MARK: - Perfume Mock for Previews

extension Perfume {
    static var mock: Perfume {
        Perfume(
            id: "mock-perfume-id",
            name: "Sauvage Elixir",
            brand: "dior",
            key: "sauvage_elixir_dior",
            family: "Oriental Especiado",
            subfamilies: ["Aromático", "Amaderado"],
            topNotes: ["Bergamota", "Cardamomo", "Nuez moscada"],
            heartNotes: ["Lavanda", "Canela", "Salvia"],
            baseNotes: ["Haba Tonka", "Sándalo", "Pachulí", "Ámbar"],
            projection: "explosive",
            intensity: "very_high",
            duration: "very_long",
            recommendedSeason: ["autumn", "winter"],
            associatedPersonalities: ["confident", "elegant", "mysterious"],
            occasion: ["nights", "dates", "formal_meetings"],
            popularity: 4.7,
            year: 2021,
            perfumist: "François Demachy",
            imageURL: "https://fimgs.net/mdimg/perfume/375x500.96904.jpg",
            description: "Una fragancia intensa y sofisticada que combina notas especiadas con un corazón amaderado.",
            gender: "male",
            price: "expensive"
        )
    }

    static var mockFavorite: Perfume {
        var perfume = Perfume.mock
        perfume.name = "Bleu de Chanel"
        perfume.popularity = 4.9
        return perfume
    }

    static var mockLowRating: Perfume {
        var perfume = Perfume.mock
        perfume.name = "Light Blue"
        perfume.brand = "dolce_gabbana"
        perfume.family = "Floral Frutal"
        perfume.popularity = 3.2
        return perfume
    }
}

// MARK: - Previews

#Preview("Compact Style - Medium") {
    PerfumeCard(
        perfume: .mock,
        brandName: "Dior",
        style: .compact,
        size: .medium,
        showsFamily: true,
        showsRating: true,
        onTap: { print("Tapped perfume") },
        onFavorite: { print("Toggled favorite") }
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}

#Preview("Compact Style - Small") {
    PerfumeCard(
        perfume: .mock,
        brandName: "Dior",
        style: .compact,
        size: .small,
        showsFamily: false,
        showsRating: true,
        score: 87.5,
        onTap: { print("Tapped perfume") }
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}

#Preview("Carousel Style") {
    PerfumeCard(
        perfume: .mock,
        brandName: "Dior",
        style: .carousel,
        size: .small,
        showsRating: true,
        score: 92.0,
        onTap: { print("Tapped perfume") }
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}

#Preview("Row Style - Personal Rating") {
    PerfumeCard(
        perfume: .mock,
        brandName: "Dior",
        style: .row,
        size: .small,
        showsRating: true,
        personalRating: 8.5,
        onTap: { print("Tapped perfume") }
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}

#Preview("Row Style - General Rating") {
    PerfumeCard(
        perfume: .mock,
        brandName: "Dior",
        style: .row,
        size: .small,
        showsRating: true,
        onTap: { print("Tapped perfume") }
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}

#Preview("Detailed Style - Full Info") {
    PerfumeCard(
        perfume: .mock,
        brandName: "Dior",
        style: .detailed,
        size: .medium,
        showsFamily: true,
        showsRating: true,
        showsNotes: true,
        showsPrice: true,
        onTap: { print("Tapped perfume") },
        onFavorite: { print("Toggled favorite") }
    )
    .padding()
    .background(AppColor.backgroundPrimary)
}

#Preview("Grid 2 Columns") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.spacing16) {
            ForEach(0..<6, id: \.self) { index in
                PerfumeCard(
                    perfume: index.isMultiple(of: 2) ? .mock : .mockLowRating,
                    brandName: "Dior",
                    style: .compact,
                    size: .medium,
                    showsFamily: true,
                    showsRating: true,
                    score: index.isMultiple(of: 2) ? Double(85 + index * 2) : nil,
                    onTap: { print("Tapped perfume \(index)") }
                )
            }
        }
        .padding()
    }
    .background(AppColor.backgroundPrimary)
    .frame(height: 600)
}

#Preview("List View") {
    ScrollView {
        LazyVStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            ForEach(0..<5, id: \.self) { index in
                PerfumeCard(
                    perfume: index.isMultiple(of: 2) ? .mock : .mockFavorite,
                    brandName: "Dior",
                    style: .row,
                    size: .small,
                    showsRating: true,
                    personalRating: index.isMultiple(of: 2) ? Double(7 + index) : nil,
                    onTap: { print("Tapped perfume \(index)") }
                )
                .padding(.horizontal, AppSpacing.spacing16)

                if index < 4 {
                    Divider()
                        .padding(.horizontal, AppSpacing.spacing16)
                }
            }
        }
    }
    .background(AppColor.backgroundPrimary)
    .frame(height: 500)
}

#Preview("Dark Mode") {
    VStack(spacing: AppSpacing.spacing24) {
        PerfumeCard(
            perfume: .mock,
            brandName: "Dior",
            style: .compact,
            size: .medium,
            showsFamily: true,
            showsRating: true,
            onTap: { print("Tapped perfume") },
            onFavorite: { print("Toggled favorite") }
        )

        PerfumeCard(
            perfume: .mockFavorite,
            brandName: "Chanel",
            style: .detailed,
            size: .medium,
            showsFamily: true,
            showsRating: true,
            showsNotes: true,
            showsPrice: true,
            onTap: { print("Tapped perfume") },
            onFavorite: { print("Toggled favorite") }
        )
    }
    .padding()
    .background(AppColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}

#Preview("Horizontal Carousel") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: AppSpacing.spacing16) {
            ForEach(0..<5, id: \.self) { index in
                PerfumeCard(
                    perfume: .mock,
                    brandName: "Dior",
                    style: .carousel,
                    size: .small,
                    showsRating: true,
                    score: Double(80 + index * 3),
                    onTap: { print("Tapped perfume \(index)") }
                )
            }
        }
        .padding()
    }
    .background(AppColor.backgroundPrimary)
    .frame(height: 200)
}
