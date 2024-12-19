import SwiftUI

enum Destination: Hashable {
    case testView
    case giftView
    case savedProfilesView
}

struct TestOlfativoMainView: View {
    @State private var path = NavigationPath()
    @State private var savedProfilesExist = true

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                // Título centrado
                Text("¿Qué deseas hacer hoy?")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                Spacer()

                // Opciones principales
                VStack(spacing: 16) {
                    OptionCard(icon: "magnifyingglass", title: "Test Personal", subtitle: "Descubre tu fragancia ideal.") {
                        path.append(Destination.testView)
                    }

                    OptionCard(icon: "gift.fill", title: "Buscar un Regalo", subtitle: "Encuentra el perfume perfecto para alguien especial.") {
                        path.append(Destination.giftView)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Botón secundario para perfiles guardados
                if savedProfilesExist {
                    Button(action: {
                        path.append(Destination.savedProfilesView)
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Ver Perfiles Guardados")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Test Olfativo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .testView:
                    TestView() // Navega a TestView
                case .giftView:
                    GiftView()
                case .savedProfilesView:
                    SavedProfilesView()
                }
            }
        }
    }
}

struct OptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.orange)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(#colorLiteral(red: 0.99, green: 0.95, blue: 0.91, alpha: 1))) // #FDF3E7
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct SavedProfilesView: View {
    var body: some View {
        Text("Perfiles Guardados")
            .font(.largeTitle)
    }
}

struct TestOlfativoMainView_Previews: PreviewProvider {
    static var previews: some View {
        TestOlfativoMainView()
    }
}
