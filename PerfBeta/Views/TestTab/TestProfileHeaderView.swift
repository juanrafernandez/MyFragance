import SwiftUI

struct TestProfileHeaderView: View {
    let profile: OlfactiveProfile
    @EnvironmentObject var familyViewModel: FamilyViewModel

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                let familySelected = familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")

                LinearGradient(
                    colors: [
                        Color(hex: familySelected?.familyColor ?? "FFFFFF").opacity(0.3),
                        .white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Principal: \(familySelected?.name ?? "Desconocido")")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#2D3748"))

                    let complementaryFamilies = profile.families
                        .dropFirst()  // Omitir la familia principal (la primera)
                        .prefix(2)    // Tomar las 2 familias siguientes
                        .compactMap { familyViewModel.getFamily(byKey: $0.family) }  // Obtener objetos `Family` completos

                    
                    if !complementaryFamilies.isEmpty {
                        Text("Complementarias: \(complementaryFamilies.map { $0.name }.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#2D3748"))
                    }

                    Text(profile.gender.capitalized)
                        .font(.footnote)
                        .foregroundColor(Color(hex: "#4A5568"))
                    
                    if let description = profile.descriptionProfile {
                        Text(description)
                            .font(.footnote)
                            .foregroundColor(Color(hex: "#4A5568"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}
