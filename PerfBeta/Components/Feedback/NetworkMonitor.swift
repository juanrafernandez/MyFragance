import SwiftUI
import Network
import Observation

/// Monitor de conectividad de red usando NWPathMonitor
/// Proporciona estado reactivo de la conexión para toda la app
@Observable
@MainActor
final class NetworkMonitor {
    // MARK: - Published Properties
    private(set) var isConnected: Bool = true
    private(set) var connectionType: NWInterface.InterfaceType?
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false

    // MARK: - Private Properties
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.perfbeta.networkmonitor")

    // MARK: - Initializer
    init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring Methods
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                // Update connection status
                self.isConnected = path.status == .satisfied

                // Update connection type (WiFi, Cellular, etc)
                self.connectionType = path.availableInterfaces.first?.type

                // Update quality flags
                self.isExpensive = path.isExpensive // True para datos móviles
                self.isConstrained = path.isConstrained // True si hay restricciones

                // Log cambios (útil para debugging)
                #if DEBUG
                self.logConnectionChange(path)
                #endif
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Helper Methods

    /// Descripción legible del tipo de conexión
    var connectionDescription: String {
        guard isConnected else { return "Sin conexión" }

        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Datos móviles"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Otra conexión"
        case .none:
            return "Conectado"
        @unknown default:
            return "Desconocido"
        }
    }

    /// True si la conexión es adecuada para operaciones pesadas
    var isGoodForHeavyOperations: Bool {
        isConnected && !isExpensive && !isConstrained
    }

    // MARK: - Private Helpers

    private func logConnectionChange(_ path: NWPath) {
        print("🌐 Network Status Changed:")
        print("   - Connected: \(path.status == .satisfied)")
        print("   - Type: \(connectionDescription)")
        print("   - Expensive: \(path.isExpensive)")
        print("   - Constrained: \(path.isConstrained)")
    }
}

// MARK: - Network Status Banner
/// Banner que se muestra automáticamente cuando no hay conexión
struct NetworkStatusBanner: View {
    let networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.body.weight(.semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sin Conexión")
                        .font(.subheadline.weight(.semibold))

                    Text("Usando datos guardados")
                        .font(.caption)
                }

                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(999) // Asegurar que esté arriba de todo
        }
    }
}

// MARK: - Enhanced Banner (con opciones de reconexión)
/// Banner mejorado con opción de forzar reconexión
struct NetworkStatusBannerEnhanced: View {
    let networkMonitor: NetworkMonitor
    @State private var isRefreshing = false

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 12) {
                // Icono animado
                Image(systemName: "wifi.slash")
                    .font(.body.weight(.semibold))
                    .symbolEffect(.pulse, options: .repeating)

                // Mensaje
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sin Conexión")
                        .font(.subheadline.weight(.semibold))

                    Text(networkMonitor.connectionDescription)
                        .font(.caption)
                }

                Spacer()

                // Botón de refresh (opcional)
                if isRefreshing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(networkMonitor.isConnected ? Color.green : Color.orange)
            .animation(.easeInOut, value: networkMonitor.isConnected)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(999)
        }
    }

    private func refresh() {
        isRefreshing = true

        // Simular intento de reconexión
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRefreshing = false

            // Feedback háptico
            if networkMonitor.isConnected {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    /// Añade el banner de estado de red en la parte superior
    /// - Parameter networkMonitor: Instancia del monitor
    func networkStatusBanner(_ networkMonitor: NetworkMonitor) -> some View {
        VStack(spacing: 0) {
            NetworkStatusBanner(networkMonitor: networkMonitor)

            self
        }
        .animation(.spring(response: 0.3), value: networkMonitor.isConnected)
    }

    /// Versión mejorada con botón de refresh
    func networkStatusBannerEnhanced(_ networkMonitor: NetworkMonitor) -> some View {
        VStack(spacing: 0) {
            NetworkStatusBannerEnhanced(networkMonitor: networkMonitor)

            self
        }
        .animation(.spring(response: 0.3), value: networkMonitor.isConnected)
    }
}

// MARK: - Previews
#Preview("Network Status Banner") {
    VStack {
        Text("Network Monitor Preview")
            .font(.title)
        Text("Banner shows when disconnected")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .networkStatusBanner(NetworkMonitor())
}

#Preview("Enhanced Network Banner") {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(0..<10) { i in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 100)
                    .overlay {
                        Text("Contenido \(i + 1)")
                    }
            }
        }
        .padding()
    }
    .networkStatusBannerEnhanced(NetworkMonitor())
}
