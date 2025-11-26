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
                .background(AppColor.brandAccent)
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
                .foregroundColor(AppColor.brandAccent)
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColor.brandAccent, lineWidth: 2)
                )
        }
    }
}
