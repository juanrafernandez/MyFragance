import SwiftUI

// MARK: - Legacy Button Styles
// ⚠️ DEPRECATED: Use AppButton component instead
// These styles are kept for backward compatibility but should be migrated to AppButton

@available(*, deprecated, message: "Use AppButton component instead")
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.labelLarge)
            .foregroundColor(AppColor.textInverse)
            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
            .background(AppColor.interactivePrimary)
            .cornerRadius(AppCornerRadius.small)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: 4, x: 0, y: 2)
    }
}

@available(*, deprecated, message: "Use AppButton component instead")
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.labelLarge)
            .foregroundColor(AppColor.textPrimary)
            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
            .background(AppColor.backgroundPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .stroke(AppColor.borderPrimary, lineWidth: 2)
            )
            .cornerRadius(AppCornerRadius.small)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: 2, x: 0, y: 1)
    }
}
