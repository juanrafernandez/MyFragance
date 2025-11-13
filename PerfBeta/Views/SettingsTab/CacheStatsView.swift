import SwiftUI

/// Vista para mostrar estadísticas de la caché en Settings
struct CacheStatsView: View {
    @State private var cacheSize: Int64 = 0
    @State private var lastSyncDate: Date?
    @State private var perfumeCount: Int = 0
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Calculando estadísticas...")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            } else {
                // Tamaño de caché
                CacheStatRow(
                    icon: "externaldrive.fill",
                    iconColor: .blue,
                    title: "Tamaño de caché",
                    value: formatBytes(cacheSize)
                )

                // Número de perfumes
                CacheStatRow(
                    icon: "tray.full.fill",
                    iconColor: .green,
                    title: "Perfumes en caché",
                    value: "\(perfumeCount)"
                )

                // Última sincronización
                CacheStatRow(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: "Última sincronización",
                    value: formatDate(lastSyncDate)
                )

                // Estado
                CacheStatRow(
                    icon: "checkmark.circle.fill",
                    iconColor: cacheSize > 0 ? .green : .gray,
                    title: "Estado",
                    value: cacheSize > 0 ? "Activo" : "Vacío"
                )

                // Botón refrescar
                Button(action: {
                    Task {
                        await loadStats()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Actualizar estadísticas")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.primary)
            }
        }
        .task {
            await loadStats()
        }
    }

    // MARK: - Load Stats

    private func loadStats() async {
        isLoading = true

        // Obtener tamaño de caché
        cacheSize = await CacheManager.shared.getCacheSize()

        // Obtener última sincronización
        lastSyncDate = await CacheManager.shared.getLastSyncTimestamp(for: "metadata_index")

        // Obtener número de perfumes en caché
        if let metadata = await CacheManager.shared.load([PerfumeMetadata].self, for: "metadata_index") {
            perfumeCount = metadata.count
        } else {
            perfumeCount = 0
        }

        isLoading = false

        #if DEBUG
        print("📊 [CacheStats] Size: \(formatBytes(cacheSize)), Perfumes: \(perfumeCount), Last Sync: \(formatDate(lastSyncDate))")
        #endif
    }

    // MARK: - Helpers

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 {
            return "0 KB"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return "Nunca"
        }

        let now = Date()
        let interval = now.timeIntervalSince(date)

        // Menos de 1 minuto
        if interval < 60 {
            return "Hace unos segundos"
        }

        // Menos de 1 hora
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Hace \(minutes) min"
        }

        // Menos de 24 horas
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Hace \(hours)h"
        }

        // Menos de 7 días
        if interval < 604800 {
            let days = Int(interval / 86400)
            return "Hace \(days) día\(days == 1 ? "" : "s")"
        }

        // Más de 7 días - mostrar fecha
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - Cache Stat Row Component

private struct CacheStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.secondary)
                .font(.subheadline)

            Spacer()

            Text(value)
                .foregroundColor(.primary)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct CacheStatsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack {
                SectionCard(title: "Estadísticas de Caché") {
                    CacheStatsView()
                }
                .padding()
            }
        }
    }
}
