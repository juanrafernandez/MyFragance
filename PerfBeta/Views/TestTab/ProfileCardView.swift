import SwiftUI

struct ProfileCardView: View {
    let title: String
    let description: String
    let gradientColors: [Color]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color("textoPrincipal"))
                    .multilineTextAlignment(.leading)

                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}
