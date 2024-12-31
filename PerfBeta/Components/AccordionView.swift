import SwiftUI

// Componente para el acordeón
struct AccordionView<Content: View>: View {
    @Binding var isExpanded: Bool
    let content: Content

    init(isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack {
            HStack {
                Text("Resumen del Test")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#2D3748"))
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .animation(.easeInOut, value: isExpanded)
            }
            .padding()
            .onTapGesture {
                isExpanded.toggle()
            }

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .slide))
            }
        }
    }
}

