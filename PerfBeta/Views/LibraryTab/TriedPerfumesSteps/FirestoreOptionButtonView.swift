import SwiftUI

/// Vista de botón para opciones cargadas desde Firestore
/// Similar a GenericOptionButtonView pero funciona con el modelo Option
struct FirestoreOptionButtonView: View {
    let option: Option
    @Binding var selectedOption: Option?
    let action: () -> Void

    var isSelected: Bool {
        selectedOption?.id == option.id
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Imagen de la opción
                if !option.image_asset.isEmpty {
                    Image(option.image_asset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(isSelected ? .white : .primary)
                        .onAppear {
                            if UIImage(named: option.image_asset) == nil {
                                #if DEBUG
                                print("⚠️ [FirestoreOptionButton] Image asset '\(option.image_asset)' not found")
                                #endif
                            }
                        }
                } else {
                    // Placeholder si no hay imagen
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "questionmark")
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(option.description)
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
        .padding(.horizontal)
    }
}
