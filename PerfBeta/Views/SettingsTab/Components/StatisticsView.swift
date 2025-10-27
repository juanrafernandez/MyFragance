import SwiftUI

/// Vista de Estadísticas detalladas del usuario
/// Muestra información sobre uso de la app, caché, datos, etc.
struct StatisticsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var cacheSize: String = "Calculando..."
    @State private var metadataCount: Int = 0
    @State private var lastSyncDate: String = "Nunca"

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.spacing24) {
                        // MARK: - Resumen General
                        StatisticsSection(title: "Tu Actividad") {
                            StatRow(
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                title: "Perfumes Probados",
                                value: "\(userViewModel.triedPerfumes.count)"
                            )

                            StatRow(
                                icon: "heart.fill",
                                iconColor: .pink,
                                title: "Lista de Deseos",
                                value: "\(userViewModel.wishlistPerfumes.count)"
                            )

                            StatRow(
                                icon: "sparkles",
                                iconColor: AppColor.brandAccent,
                                title: "Perfiles Olfativos",
                                value: "\(olfactiveProfileViewModel.profiles.count)"
                            )

                            StatRow(
                                icon: "star.fill",
                                iconColor: .yellow,
                                title: "Perfumes Favoritos",
                                value: "\(userViewModel.user?.favoritePerfumes.count ?? 0)"
                            )
                        }

                        // MARK: - Datos Locales
                        StatisticsSection(title: "Almacenamiento Local") {
                            StatRow(
                                icon: "externaldrive.fill",
                                iconColor: .blue,
                                title: "Tamaño de Caché",
                                value: cacheSize
                            )

                            StatRow(
                                icon: "doc.on.doc.fill",
                                iconColor: .purple,
                                title: "Perfumes en Caché",
                                value: "\(metadataCount)"
                            )

                            StatRow(
                                icon: "clock.arrow.circlepath",
                                iconColor: .orange,
                                title: "Última Sincronización",
                                value: lastSyncDate
                            )
                        }

                        // MARK: - Catálogo
                        StatisticsSection(title: "Catálogo Disponible") {
                            StatRow(
                                icon: "scope",
                                iconColor: AppColor.brandAccent,
                                title: "Total de Perfumes",
                                value: "\(perfumeViewModel.metadataIndex.count)"
                            )

                            StatRow(
                                icon: "building.2.fill",
                                iconColor: .brown,
                                title: "Marcas Disponibles",
                                value: uniqueBrandsCount
                            )

                            StatRow(
                                icon: "leaf.fill",
                                iconColor: .green,
                                title: "Familias Olfativas",
                                value: uniqueFamiliesCount
                            )
                        }

                        // MARK: - Progreso
                        if userViewModel.triedPerfumes.count > 0 {
                            StatisticsSection(title: "Tu Progreso") {
                                VStack(spacing: AppSpacing.spacing12) {
                                    ProgressStat(
                                        title: "Exploración del Catálogo",
                                        current: userViewModel.triedPerfumes.count,
                                        total: perfumeViewModel.metadataIndex.count,
                                        color: .green
                                    )

                                    if let avgRating = averageRating {
                                        HStack {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)

                                            Text("Valoración Media")
                                                .font(AppTypography.bodyMedium)
                                                .foregroundColor(AppColor.textPrimary)

                                            Spacer()

                                            HStack(spacing: 2) {
                                                Text(String(format: "%.1f", avgRating))
                                                    .font(AppTypography.titleMedium)
                                                    .foregroundColor(AppColor.brandAccent)

                                                Text("/ 5.0")
                                                    .font(AppTypography.bodySmall)
                                                    .foregroundColor(AppColor.textSecondary)
                                            }
                                        }
                                        .padding(AppSpacing.spacing12)
                                        .background(AppColor.surfaceCard)
                                        .cornerRadius(AppCornerRadius.medium)
                                    }
                                }
                            }
                        }

                        // MARK: - Info Adicional
                        VStack(spacing: AppSpacing.spacing8) {
                            Text("Los datos se sincronizan automáticamente cada 24 horas o cuando abres la app.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColor.textTertiary)
                                .multilineTextAlignment(.center)

                            Text("El caché local permite usar la app offline.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColor.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppSpacing.spacing20)
                        .padding(.top, AppSpacing.spacing16)

                        Color.clear.frame(height: AppSpacing.spacing20)
                    }
                    .padding(.horizontal, AppSpacing.spacing16)
                    .padding(.top, AppSpacing.spacing16)
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.brandAccent)
                }
            }
        }
        .task {
            await loadStatistics()
        }
    }

    // MARK: - Computed Properties

    private var uniqueBrandsCount: String {
        let brands = Set(perfumeViewModel.metadataIndex.map { $0.brand })
        return "\(brands.count)"
    }

    private var uniqueFamiliesCount: String {
        let families = Set(perfumeViewModel.metadataIndex.map { $0.family })
        return "\(families.count)"
    }

    private var averageRating: Double? {
        let ratings = userViewModel.triedPerfumes.compactMap { $0.rating }
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    // MARK: - Load Statistics

    private func loadStatistics() async {
        // Cargar tamaño de caché
        await calculateCacheSize()

        // Metadata count
        metadataCount = perfumeViewModel.metadataIndex.count

        // Last sync date
        if let lastSync = await CacheManager.shared.getLastSyncTimestamp(for: "metadata_index") {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            lastSyncDate = formatter.localizedString(for: lastSync, relativeTo: Date())
        }
    }

    private func calculateCacheSize() async {
        do {
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let size = try await getCacheDirectorySize(url: cacheDir)

            await MainActor.run {
                cacheSize = formatBytes(size)
            }
        } catch {
            await MainActor.run {
                cacheSize = "N/A"
            }
        }
    }

    private func getCacheDirectorySize(url: URL) async throws -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(fileAttributes.fileSize ?? 0)
            }
        }

        return totalSize
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Statistics Section

struct StatisticsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing12) {
            Text(title)
                .font(AppTypography.titleMedium)
                .foregroundColor(AppColor.textPrimary)

            VStack(spacing: AppSpacing.spacing8) {
                content
            }
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 32)

            Text(title)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColor.textPrimary)

            Spacer()

            Text(value)
                .font(AppTypography.titleSmall)
                .foregroundColor(AppColor.brandAccent)
        }
        .padding(AppSpacing.spacing12)
        .background(AppColor.surfaceCard)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Progress Stat

struct ProgressStat: View {
    let title: String
    let current: Int
    let total: Int
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (Double(current) / Double(total)) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.spacing8) {
            HStack {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColor.textPrimary)

                Spacer()

                Text("\(current) / \(total)")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColor.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(String(format: "%.1f", percentage))% completado")
                .font(AppTypography.caption)
                .foregroundColor(AppColor.textTertiary)
        }
        .padding(AppSpacing.spacing12)
        .background(AppColor.surfaceCard)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - Preview
#Preview {
    let authVM = AuthViewModel(authService: DependencyContainer.shared.authService)
    let userVM = UserViewModel(
        userService: DependencyContainer.shared.userService,
        authViewModel: authVM
    )
    let olfactiveVM = OlfactiveProfileViewModel(
        olfactiveProfileService: DependencyContainer.shared.olfactiveProfileService,
        authViewModel: authVM
    )
    let perfumeVM = PerfumeViewModel(perfumeService: DependencyContainer.shared.perfumeService)

    return StatisticsView()
        .environmentObject(userVM)
        .environmentObject(olfactiveVM)
        .environmentObject(perfumeVM)
}
