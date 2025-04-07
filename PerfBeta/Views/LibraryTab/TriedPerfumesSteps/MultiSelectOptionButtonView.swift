import SwiftUI

struct MultiSelectOptionButtonView<OptionType: SelectableOption>: View {
    let optionCase: OptionType
    @Binding var selectedOptions: Set<OptionType>
    let action: () -> Void

    var isSelected: Bool {
        selectedOptions.contains(optionCase)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Imagen de la opción (¡TAMAÑO AUMENTADO a 60x60 y aspectRatio a .fill!)
                Image(optionCase.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill) // ¡CAMBIADO a .fill!
                    .frame(width: 60, height: 60)    // ¡AUMENTADO a 60x60!
                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Añadido clipShape para que coincida con OptionButton
                    .foregroundColor(isSelected ? .white : .primary)
                    .onAppear {
                        if UIImage(named: optionCase.imageName) == nil {
                            print("Image asset named '\(optionCase.imageName)' not found, using placeholder.")
                        }
                    }

                // Contenido textual de la opción (sin cambios)
                VStack(alignment: .leading, spacing: 4) {
                    Text(optionCase.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(optionCase.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .padding(.vertical, 18)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    if isSelected {
                        Color.blue
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    }
                }
            )
        }
        
    }
}
