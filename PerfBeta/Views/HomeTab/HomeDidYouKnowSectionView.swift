import SwiftUI

// Sección ¿Sabías que...?
struct HomeDidYouKnowSectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Sabías que…?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal)

            Text("La vainilla es uno de los ingredientes más caros del mundo.")
                .font(.system(size: 14))
                .foregroundColor(Color("textoSecundario"))
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("grisSuave"))
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}
