import SwiftUI
import UIKit
import Kingfisher
import StoreKit

/// Vista principal de Ajustes - Fase 1 (Lo Esencial)
/// Mejoras UX siguiendo mejores prácticas del mercado
struct SettingsViewNew: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    // State para modals y alerts
    @State private var showingEditProfile = false
    @State private var showingStatistics = false
    @State private var showingClearCacheAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingMailComposer = false
    @State private var showingAbout = false
    @State private var cacheMessage = ""
    @State private var isClearingCache = false

    // Cache status
    @State private var cacheSize: String = "Calculando..."
    @State private var lastSyncDate: String = "Nunca"

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.spacing24) {
                        // MARK: - Header con Perfil y Stats
                        SettingsHeaderView(
                            userName: authViewModel.currentUser?.displayName ?? "Usuario",
                            userEmail: authViewModel.currentUser?.email ?? "",
                            triedCount: userViewModel.triedPerfumes.count,
                            wishlistCount: userViewModel.wishlistPerfumes.count,
                            profilesCount: olfactiveProfileViewModel.profiles.count,
                            onEditProfile: { showingEditProfile = true }
                        )

                        // MARK: - Sección: Mi Cuenta
                        SettingsSectionView(
                            title: "Mi Cuenta",
                            footer: "Gestiona tu información personal"
                        ) {
                            SettingsRowView(
                                icon: "person.fill",
                                iconColor: .blue,
                                title: "Editar Perfil",
                                subtitle: "Nombre y foto",
                                action: { showingEditProfile = true }
                            )

                            SettingsRowView(
                                icon: "arrow.right.square.fill",
                                iconColor: .red,
                                title: "Cerrar Sesión",
                                action: { showingSignOutAlert = true }
                            )
                        }

                        // MARK: - Sección: Datos y Almacenamiento
                        SettingsSectionView(
                            title: "Datos y Almacenamiento",
                            footer: "Gestiona la caché local para liberar espacio"
                        ) {
                            SettingsRowView(
                                icon: "chart.bar.fill",
                                iconColor: .purple,
                                title: "Estadísticas",
                                subtitle: "Ver uso de datos",
                                action: { showingStatistics = true }
                            )

                            // ✅ Cache Status
                            SettingsRowView(
                                icon: "externaldrive.fill",
                                iconColor: .blue,
                                title: "Estado de Caché",
                                subtitle: "Tamaño: \(cacheSize) • Sync: \(lastSyncDate)",
                                showChevron: false,
                                action: nil
                            )

                            SettingsRowView(
                                icon: "trash.fill",
                                iconColor: .orange,
                                title: "Limpiar Caché",
                                subtitle: isClearingCache ? "Limpiando..." : "Libera espacio en tu dispositivo",
                                action: { clearCache() }
                            )
                        }

                        // MARK: - Sección: Soporte
                        SettingsSectionView(
                            title: "Soporte",
                            footer: "¿Necesitas ayuda? Estamos aquí para ti"
                        ) {
                            SettingsRowView(
                                icon: "envelope.fill",
                                iconColor: AppColor.brandAccent,
                                title: "Escribir al Desarrollador",
                                subtitle: "Envía tus comentarios",
                                action: { openMailComposer() }
                            )

                            SettingsRowView(
                                icon: "star.fill",
                                iconColor: .yellow,
                                title: "Valorar en App Store",
                                subtitle: "Ayúdanos a mejorar",
                                action: { rateApp() }
                            )

                            SettingsRowView(
                                icon: "square.and.arrow.up.fill",
                                iconColor: .green,
                                title: "Compartir PerfBeta",
                                subtitle: "Comparte con tus amigos",
                                action: { shareApp() }
                            )
                        }

                        // MARK: - Sección: Información
                        SettingsSectionView(title: "Información") {
                            SettingsRowView(
                                icon: "info.circle.fill",
                                iconColor: .gray,
                                title: "Versión",
                                value: appVersion,
                                showChevron: false,
                                action: nil
                            )

                            SettingsRowView(
                                icon: "heart.fill",
                                iconColor: .pink,
                                title: "Acerca de PerfBeta",
                                action: { showingAbout = true }
                            )
                        }

                        // Spacer para padding bottom
                        Color.clear.frame(height: AppSpacing.spacing20)
                    }
                    .padding(.horizontal, AppSpacing.spacing16)
                    .padding(.top, AppSpacing.spacing16)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadCacheStatus()
            }
        }
        // MARK: - Sheets y Alerts
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
                .environmentObject(userViewModel)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
                .environmentObject(userViewModel)
                .environmentObject(olfactiveProfileViewModel)
                .environmentObject(perfumeViewModel)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Limpiar Caché", isPresented: $showingClearCacheAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cacheMessage)
        }
        .alert("Cerrar Sesión", isPresented: $showingSignOutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
    }

    // MARK: - Computed Properties
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    /// ✅ Carga información del estado de la caché
    private func loadCacheStatus() {
        Task {
            // 1. Calcular tamaño de caché
            let cacheManager = CacheManager.shared
            let sizeInBytes = await cacheManager.getCacheSize()

            // 2. Obtener fecha de última sincronización
            let lastSync = await cacheManager.getLastSyncTimestamp(for: "perfume_metadata_index")

            await MainActor.run {
                // Formatear tamaño
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                formatter.allowedUnits = [.useKB, .useMB, .useGB]
                self.cacheSize = formatter.string(fromByteCount: sizeInBytes)

                // Formatear fecha
                if let lastSync = lastSync {
                    let timeInterval = Date().timeIntervalSince(lastSync)
                    if timeInterval < 60 {
                        self.lastSyncDate = "Hace un momento"
                    } else if timeInterval < 3600 {
                        let minutes = Int(timeInterval / 60)
                        self.lastSyncDate = "Hace \(minutes) min"
                    } else if timeInterval < 86400 {
                        let hours = Int(timeInterval / 3600)
                        self.lastSyncDate = "Hace \(hours)h"
                    } else {
                        let days = Int(timeInterval / 86400)
                        self.lastSyncDate = "Hace \(days)d"
                    }
                } else {
                    self.lastSyncDate = "Nunca"
                }
            }
        }
    }

    private func clearCache() {
        isClearingCache = true

        Task {
            do {
                #if DEBUG
                print("⚙️ SettingsView: Limpiando caché...")
                #endif

                // 1. Limpiar CacheManager (metadata, perfumes, etc.)
                let cacheManager = CacheManager.shared
                let cacheKeys = [
                    "perfume_metadata_index",
                    "metadata_last_sync"
                ]

                for key in cacheKeys {
                    await cacheManager.clearCache(for: key)
                }

                // 2. Limpiar caché de Kingfisher (imágenes)
                await MainActor.run {
                    ImageCache.default.clearMemoryCache()
                    ImageCache.default.clearDiskCache()
                }

                // 3. Limpiar caché de Firestore
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.clearFirestoreCache()
                }

                await MainActor.run {
                    isClearingCache = false
                    cacheMessage = "✅ Caché limpiada correctamente.\n\nSe han eliminado:\n• Metadata de perfumes\n• Imágenes en caché\n• Datos de Firestore\n\nReinicia la app para recargar los datos."
                    showingClearCacheAlert = true
                }

                // ✅ Recargar cache status después de limpiar
                loadCacheStatus()

                #if DEBUG
                print("✅ Caché limpiada exitosamente")
                #endif
            } catch {
                await MainActor.run {
                    isClearingCache = false
                    cacheMessage = "❌ Error al limpiar la caché: \(error.localizedDescription)"
                    showingClearCacheAlert = true
                }
                #if DEBUG
                print("❌ Error limpiando caché: \(error)")
                #endif
            }
        }
    }

    private func openMailComposer() {
        let email = "juanra.fernandez@gmail.com"
        let subject = "Feedback PerfBeta"
        let body = """


        ---
        Versión: \(appVersion)
        Dispositivo: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        """

        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        // Usa SKStoreReviewController para solicitar review in-app
        // Esto funciona en desarrollo y producción
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }

        // Nota: Cuando la app esté publicada, también puedes usar:
        // let appStoreURL = "https://apps.apple.com/app/id[TU_APP_ID]?action=write-review"
        // Para llevar al usuario directamente a escribir una review
    }

    private func shareApp() {
        let message = "¡Descubre PerfBeta! 🌸\n\nLa mejor app para encontrar tu perfume ideal basándote en tu perfil olfativo personalizado.\n\nExplora más de 5,000 fragancias y recibe recomendaciones perfectas para ti."

        // Intentar obtener el icono de la app
        var items: [Any] = [message]

        // Agregar icono de la app si está disponible
        if let appIcon = UIImage(named: "AppIcon") {
            items.insert(appIcon, at: 0)
        }

        // Si la app ya está publicada, agregar el URL:
        // let appURL = URL(string: "https://apps.apple.com/app/id[TU_APP_ID]")!
        // items.append(appURL)

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Configurar para iPad (popover)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.spacing24) {
                        // App Icon
                        Image("AppIcon") // TODO: Verificar nombre del asset
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                            .shadow(.medium)
                            .padding(.top, AppSpacing.spacing32)

                        // App Name
                        Text("PerfBeta")
                            .font(AppTypography.displaySmall)
                            .foregroundColor(AppColor.textPrimary)

                        Text("Descubre tu perfume ideal")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColor.textSecondary)

                        Divider()
                            .padding(.horizontal, AppSpacing.spacing40)

                        // Description
                        VStack(spacing: AppSpacing.spacing16) {
                            Text("PerfBeta es tu asistente personal para descubrir fragancias que se adaptan a tu personalidad y preferencias.")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColor.textSecondary)
                                .multilineTextAlignment(.center)

                            Text("Crea tu perfil olfativo, explora recomendaciones personalizadas y gestiona tu colección de perfumes.")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColor.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppSpacing.spacing32)

                        // Credits
                        VStack(spacing: AppSpacing.spacing8) {
                            Text("Desarrollado con ❤️")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColor.textTertiary)

                            Text("© 2024 PerfBeta")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColor.textTertiary)
                        }
                        .padding(.top, AppSpacing.spacing32)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(AppColor.brandAccent)
                }
            }
        }
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

    return SettingsViewNew()
        .environmentObject(authVM)
        .environmentObject(userVM)
        .environmentObject(olfactiveVM)
        .environmentObject(perfumeVM)
}
