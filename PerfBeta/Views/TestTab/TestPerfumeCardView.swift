import SwiftUI

struct TestPerfumeCardView: View {
    let perfume: Perfume

    var body: some View {
        VStack(spacing: 4) {
            
            if let imageURLString = perfume.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 100)
                        .cornerRadius(8)
                } placeholder: {
                    Image("placeholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 100)
                        .cornerRadius(8)
                }
            }
            
            Text(perfume.name)
                .font(.headline)
                .foregroundColor(Color(hex: "#2D3748"))
                .multilineTextAlignment(.center)

            Text(perfume.topNotes?.prefix(6).joined(separator: ", ") ?? "")
                .font(.subheadline)
                .foregroundColor(Color(hex: "#4A5568"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(8)
        .frame(width: 120)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
}
