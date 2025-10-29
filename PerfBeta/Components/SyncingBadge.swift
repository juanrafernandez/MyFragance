import SwiftUI

/// ✅ OFFLINE-FIRST: Badge discreto que indica sync en background
/// Aparece en la parte superior de las vistas cuando está actualizando datos
/// sin bloquear la UI
struct SyncingBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.white)

            Text("Actualizando...")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: UUID()) // Anima entrada/salida
    }
}

/// ✅ Badge para indicar modo offline
struct OfflineBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundColor(.white)

            Text("Sin conexión")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: UUID())
    }
}

// MARK: - Previews
#if DEBUG
struct SyncingBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncingBadge()
            OfflineBadge()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
