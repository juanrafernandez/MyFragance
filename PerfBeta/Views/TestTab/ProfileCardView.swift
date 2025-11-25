import SwiftUI

struct ProfileCardView: View {
    let title: String
    let description: String
    let familyColors: [String] // Array de hasta 3 colores de familias (hex)
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .multilineTextAlignment(.leading)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Tres círculos de colores representando familias olfativas
            HStack(spacing: 4) {
                ForEach(familyColors.prefix(3), id: \.self) { familyKey in
                    if let family = familyViewModel.getFamily(byKey: familyKey) {
                        let colorHex = family.familyColor ?? "#CCCCCC"
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 0.5)
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
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}
