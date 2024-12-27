import SwiftUI

struct PrimaryButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(TextStyle.buttonBold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.primaryChampagne)
                .cornerRadius(8)
        }
    }
}

struct SecondaryButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(TextStyle.buttonBold)
                .foregroundColor(.primaryChampagne)
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primaryChampagne, lineWidth: 2)
                )
        }
    }
}
