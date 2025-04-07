import SwiftUI

// MARK: - AddPerfumeStep8View
struct AddPerfumeStep9View: View {
    @Binding var impressions: String
    @Binding var ratingValue: Double
    @EnvironmentObject var userViewModel: UserViewModel

    var body: some View {
        VStack(alignment: .leading) { // Alineación leading para el título "Impresiones"

            Text("Impresiones") // Título "Impresiones" alineado a la izquierda
                .font(.subheadline)
                .foregroundColor(Color("textoPrincipal"))

            Text("Describe tus impresiones del perfume (mínimo 30, máximo 2000 caracteres)") // Guidance text
                .font(.caption) // Smaller font for guidance
                .foregroundColor(.gray)
                .padding(.bottom, 2)

            TextEditor(text: $impressions)
                .frame(height: 200)
                .border(Color.gray, width: 0.5)

            HStack {
                Spacer()
                Text("\(impressions.count)/2000 caracteres")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.bottom)


            VStack(alignment: .leading) {
                HStack {
                    Text("Valoración:")
                    Spacer()
                }
                Slider(value: $ratingValue, in: 0...10, step: 0.1) // Slider con step de 0.1
                Text("\(String(format: "%.1f", ratingValue))") // Muestra la valoración con 1 decimal
                    .font(.largeTitle) // Make the text larger
                    .multilineTextAlignment(.center) // Center the text alignment
                    .frame(maxWidth: .infinity, alignment: .center) // Center the text in the frame
                    .padding(.top, 4) // Add a little space above the text
                    .padding(.bottom, 10) // Add a little space below the text for visual balance
            }
        }
    }
}
