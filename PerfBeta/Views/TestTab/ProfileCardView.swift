import SwiftUI

/// Card de perfil con estilo editorial
struct ProfileCardView: View {
    let title: String
    let description: String
    let familyColors: [String] // Array de hasta 3 colores de familias (keys)
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                // Título en Georgia (estilo editorial)
                Text(title)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(AppColor.textPrimary)
                    .multilineTextAlignment(.leading)

                // Descripción
                Text(description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Tres círculos de colores representando familias olfativas
            HStack(spacing: 5) {
                ForEach(familyColors.prefix(3), id: \.self) { familyKey in
                    if let family = familyViewModel.getFamily(byKey: familyKey) {
                        let colorHex = family.familyColor ?? "#CCCCCC"
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 10, height: 10)
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}
