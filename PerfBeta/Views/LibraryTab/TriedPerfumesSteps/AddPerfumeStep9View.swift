import SwiftUI

// MARK: - AddPerfumeStep8View
struct AddPerfumeStep9View: View {
    @Binding var impressions: String
    @Binding var ratingValue: Double
    @EnvironmentObject var userViewModel: UserViewModel

    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) { // Alineación leading para el título "Impresiones"

                Text("Impresiones") // Título "Impresiones" alineado a la izquierda
                    .font(.subheadline)
                    .foregroundColor(AppColor.textPrimary)

                Text("Describe tus impresiones del perfume (mínimo 30, máximo 2000 caracteres)") // Guidance text
                    .font(.caption) // Smaller font for guidance
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $impressions)
                        .frame(height: 200)
                        .focused($isTextEditorFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Listo") {
                                    isTextEditorFocused = false
                                }
                            }
                        }

                    if impressions.isEmpty {
                        Text("Escribe tus impresiones aquí...")
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

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
                    Slider(value: $ratingValue, in: 0...10, step: 0.1)
                    Text("\(String(format: "%.1f", ratingValue))")
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Ocultar teclado al tocar fuera del TextEditor
                isTextEditorFocused = false
            }
        }
    }
}
