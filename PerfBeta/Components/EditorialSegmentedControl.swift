import SwiftUI

/// Segmented Control con estilo editorial
/// Usa bordes sutiles y tipografía refinada
struct EditorialSegmentedControl<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                }) {
                    Text(option.rawValue)
                        .font(.system(size: 14, weight: selection == option ? .medium : .regular))
                        .foregroundColor(selection == option ? AppColor.textPrimary : AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selection == option ? Color.white : Color.clear)
                                .shadow(
                                    color: selection == option ? Color.black.opacity(0.08) : Color.clear,
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColor.textSecondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
