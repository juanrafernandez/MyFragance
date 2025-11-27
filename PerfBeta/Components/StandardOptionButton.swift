import SwiftUI

/// Botón de opción estandarizado SIN imagen (Estilo Editorial)
/// Usado en todos los flujos de preguntas (Test Personal, Regalo, etc.)
struct StandardOptionButton: View {
    let label: String
    let description: String?
    let isSelected: Bool
    let showDescription: Bool
    let action: () -> Void

    init(
        label: String,
        description: String? = nil,
        isSelected: Bool,
        showDescription: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.description = description
        self.isSelected = isSelected
        self.showDescription = showDescription
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Label en Georgia (estilo editorial)
                        Text(label)
                            .font(.custom("Georgia", size: 16))
                            .foregroundColor(isSelected ? .white : AppColor.textPrimary)
                            .multilineTextAlignment(.leading)

                        if showDescription, let description = description {
                            Text(description)
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(isSelected ? .white.opacity(0.85) : AppColor.textSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColor.brandAccent : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.clear : AppColor.textSecondary.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? AppColor.brandAccent.opacity(0.3) : Color.black.opacity(0.04),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Conveniences for Question/Option

extension StandardOptionButton {
    /// Inicializador para Option (modelo de test personal)
    init(
        option: Option,
        isSelected: Bool,
        showDescription: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            label: option.label,
            description: option.description,
            isSelected: isSelected,
            showDescription: showDescription,
            action: action
        )
    }

    /// Inicializador para Option (modelo de regalo)
    init(
        giftOption: Option,
        isSelected: Bool,
        showDescription: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(
            label: giftOption.label,
            description: giftOption.description,
            isSelected: isSelected,
            showDescription: showDescription,
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Not Selected") {
    ZStack {
        GradientView(preset: .champan)
            .edgesIgnoringSafeArea(.all)

        VStack(spacing: 16) {
            StandardOptionButton(
                label: "Fresco y Cítrico",
                description: "Aromas frescos, vivaces y energizantes",
                isSelected: false
            ) {}

            StandardOptionButton(
                label: "Elegante y Sofisticado",
                description: "Fragancias complejas y refinadas para ocasiones especiales",
                isSelected: true
            ) {}
        }
        .padding()
    }
}
