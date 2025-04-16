import SwiftUI

struct CurvedHeaderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Line to top-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Line to bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Add the curve to bottom-left
        // Control points determine the curve's shape. Adjust these!
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX / 2, y: rect.maxY + 40) // Control point below the middle-left
            // Experiment with the control point Y value (+40) to change the curve depth
            // You might need addCurve for a more S-like shape if desired
        )
        // Close the path
        path.closeSubpath()
        return path
    }
}

// MARK: - Login Header Content

struct LoginHeaderView: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 60) // Adjust for status bar
            Text("Hello!")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Text("Welcome to plantland")
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
             Image("plant_illustration") // Add your plant image to Assets
                 .resizable()
                 .scaledToFit()
                 .frame(height: 100) // Adjust size
                 .padding(.bottom, -20) // Overlap slightly with the curve bottom
        }
        .frame(maxWidth: .infinity)

    }
}