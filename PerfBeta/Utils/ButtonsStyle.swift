import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color("ButtonTextColor"))
            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
            .background(Color("PrimaryButtonColor"))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: 4, x: 0, y: 2)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(Color("SecondaryButtonTextColor"))
            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
            .background(Color("SecondaryButtonBackgroundColor"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("SecondaryButtonBorderColor"), lineWidth: 3)
            )
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: 2, x: 0, y: 1)
    }
}
