import Combine
import SwiftUI

// MARK: - Data Integrity Checker
/// Utility to check data integrity between user records and perfume database
struct DataIntegrityChecker {

    /// Result of checking a single perfume key
    struct PerfumeCheckResult {
        let perfumeKey: String
        let brandKey: String
        let exists: Bool
        let source: String // "TriedPerfumes" or "Wishlist"
    }

    /// Summary of integrity check
    struct IntegrityReport {
        let totalChecked: Int
        let existingPerfumes: Int
        let orphanedPerfumes: Int
        let orphanedDetails: [PerfumeCheckResult]

        var healthPercentage: Double {
            guard totalChecked > 0 else { return 100.0 }
            return (Double(existingPerfumes) / Double(totalChecked)) * 100.0
        }

        func printReport() {
            print("=== DATA INTEGRITY REPORT ===")
            print("Total perfumes checked: \(totalChecked)")
            print("✅ Existing in database: \(existingPerfumes)")
            print("❌ Orphaned (not found): \(orphanedPerfumes)")
            print("📊 Data health: \(String(format: "%.1f", healthPercentage))%")

            if !orphanedDetails.isEmpty {
                print("\n⚠️ ORPHANED PERFUMES:")
                for detail in orphanedDetails {
                    print("  • [\(detail.source)] \(detail.brandKey)/\(detail.perfumeKey)")
                }
            } else {
                print("\n✅ No orphaned perfumes found - all references are valid!")
            }
            print("=============================")
        }
    }

    /// Check integrity of user's tried perfumes and wishlist against perfume database
    static func checkUserDataIntegrity(
        triedPerfumes: [TriedPerfumeRecord],
        wishlistItems: [WishlistItem],
        perfumeIndex: [String: Perfume]
    ) -> IntegrityReport {
        var results: [PerfumeCheckResult] = []

        // Check tried perfumes
        for record in triedPerfumes {
            let exists = perfumeIndex[record.perfumeKey] != nil
            results.append(PerfumeCheckResult(
                perfumeKey: record.perfumeKey,
                brandKey: record.brandId,
                exists: exists,
                source: "TriedPerfumes"
            ))
        }

        // Check wishlist items
        for item in wishlistItems {
            let exists = perfumeIndex[item.perfumeKey] != nil
            results.append(PerfumeCheckResult(
                perfumeKey: item.perfumeKey,
                brandKey: item.brandKey,
                exists: exists,
                source: "Wishlist"
            ))
        }

        let orphaned = results.filter { !$0.exists }

        return IntegrityReport(
            totalChecked: results.count,
            existingPerfumes: results.count - orphaned.count,
            orphanedPerfumes: orphaned.count,
            orphanedDetails: orphaned
        )
    }
}

// MARK: - UserViewModel
@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var wishlistPerfumes: [WishlistItem] = []
    @Published var triedPerfumes: [TriedPerfumeRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString? // Asume que tienes este tipo definido

    // Dependencias: El servicio y AuthViewModel (para obtener ID actual)
    private let userService: UserServiceProtocol
    private let authViewModel: AuthViewModel // Añadido como dependencia
    private let perfumeService: PerfumeServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // *** CORREGIDO: Eliminado el valor por defecto ***
    // Ahora siempre requiere un servicio y el AuthViewModel
    init(
        userService: UserServiceProtocol,
        authViewModel: AuthViewModel,
        perfumeService: PerfumeServiceProtocol = DependencyContainer.shared.perfumeService
    ) {
        self.userService = userService
        self.authViewModel = authViewModel
        self.perfumeService = perfumeService

        // Observar cambios en el usuario para cargar/limpiar datos
        authViewModel.$currentUser
            .sink { [weak self] currentUser in
                guard let self = self else { return }
                if let user = currentUser, !user.id.isEmpty {
                    // Cargar datos cuando hay usuario
                    // Llamamos a Task para no bloquear el Sink
                    Task {
                        await self.loadInitialUserData(userId: user.id)
                    }
                } else {
                    // Limpiar datos si no hay usuario
                    self.clearUserData()
                }
            }
            .store(in: &cancellables)
    }

    // Función combinada para cargar todo al inicio o cuando el usuario cambie
    private func loadInitialUserData(userId: String) async {
        guard !isLoading else { return } // Evitar cargas múltiples
        isLoading = true
        errorMessage = nil
        print("UserViewModel: Loading initial data for user \(userId)")
        do {
            // Cargar usuario, wishlist y tried en paralelo si es posible
            async let userFetch = userService.fetchUser(by: userId)
            async let wishlistFetch = userService.fetchWishlist(for: userId)
            async let triedFetch = userService.fetchTriedPerfumes(for: userId)

            // Esperar resultados
            self.user = try await userFetch
            self.wishlistPerfumes = try await wishlistFetch
            self.triedPerfumes = try await triedFetch

            print("UserViewModel: Initial data loaded successfully.")

            // Run data integrity check
            await runDataIntegrityCheck()

        } catch {
            print("🔴 UserViewModel: Error loading initial user data: \(error)")
            handleError("Error al cargar datos iniciales: \(error.localizedDescription)")
            // Limpiar datos si la carga falla
            clearUserData(keepError: true)
        }
        isLoading = false
    }

    // Limpiar datos (llamado en logout o error de carga inicial)
    private func clearUserData(keepError: Bool = false) {
        user = nil
        wishlistPerfumes = []
        triedPerfumes = []
        if !keepError {
             errorMessage = nil
        }
        // No necesitamos cambiar isLoading aquí normalmente
        print("UserViewModel: User data cleared.")
    }

    // Las funciones loadUserData, loadTriedPerfumes, loadWishlist individuales
    // podrían eliminarse si loadInitialUserData hace todo, o mantenerse
    // si necesitas recargar secciones específicas. Si las mantienes,
    // asegúrate de que obtengan el userId del authViewModel.

    // Ejemplo de cómo se vería loadTriedPerfumes si se mantiene:
    func loadTriedPerfumes() async {
        guard let userId = authViewModel.currentUser?.id else { return } // Obtener ID actual
        isLoading = true
        errorMessage = nil
        do {
            triedPerfumes = try await userService.fetchTriedPerfumes(for: userId)
        } catch {
            handleError("Error al cargar perfumes probados: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // Ejemplo de addTriedPerfume obteniendo userId de authViewModel
    func addTriedPerfume(perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String, occasions: [String]?, seasons: [String]?, personalities: [String]?) async {
        guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            // Pasar el userId obtenido al servicio
            try await userService.addTriedPerfume(userId: userId, perfumeId: perfumeId, perfumeKey: perfumeKey, brandId: brandId, projection: projection, duration: duration, price: price, rating: rating, impressions: impressions, occasions: occasions, seasons: seasons, personalities: personalities)
            await loadTriedPerfumes() // Recargar usando el método que obtiene userId internamente
        } catch {
            handleError("Error al añadir perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // Adapta las demás funciones (update, delete, wishlist) de forma similar
    // para obtener el userId desde self.authViewModel.currentUser?.id

    func updateTriedPerfume(record: TriedPerfumeRecord) async { // Simplificado, asume record ya tiene userId
        guard authViewModel.currentUser?.id == record.userId else {
            handleError("Error de permisos o usuario incorrecto.")
            return
        }
        guard let recordId = record.id else {
             handleError("ID de registro inválido para actualizar.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            // El record ya tiene el userId correcto
            let success = try await userService.updateTriedPerfumeRecord(record: record)
            if success {
                print("Perfume probado actualizado exitosamente con ID: \(recordId)")
                await loadTriedPerfumes()
            } else {
                handleError("Error al actualizar el perfume probado.")
            }
        } catch {
            handleError("Error al actualizar el perfume probado: \(error.localizedDescription)")
        }
        isLoading = false
    }

     func deleteTriedPerfume(recordId: String) async {
        guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.deleteTriedPerfumeRecord(userId: userId, recordId: recordId)
            // Optimista: eliminar de la lista local inmediatamente
            triedPerfumes.removeAll { $0.id == recordId }
            // O recargar: await loadTriedPerfumes()
            print("Registro eliminado exitosamente.")
        } catch {
             handleError("Error al eliminar perfume probado: \(error.localizedDescription)")
        }
         isLoading = false
    }

    // --- WISH LIST ---

    func loadWishlist() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        do {
            wishlistPerfumes = try await userService.fetchWishlist(for: userId)
        } catch {
            handleError("Error al cargar la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func addToWishlist(wishlistItem: WishlistItem) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.addToWishlist(userId: userId, wishlistItem: wishlistItem)
            await loadWishlist()
        } catch {
            handleError("Error al añadir a la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func removeFromWishlist(wishlistItem: WishlistItem) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Usuario no autenticado.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await userService.removeFromWishlist(userId: userId, wishlistItem: wishlistItem)
            await loadWishlist()
        } catch {
            handleError("Error al eliminar de la wishlist: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func updateWishlistOrder(orderedPerfumes: [WishlistItem]) async {
         guard let userId = authViewModel.currentUser?.id else {
             handleError("Usuario no autenticado.")
             return
         }
        // La UI se actualiza por el binding, solo persistimos
        isLoading = true
        errorMessage = nil
        let previousOrder = self.wishlistPerfumes // Guardar por si hay error
        self.wishlistPerfumes = orderedPerfumes // Actualización optimista (opcional)

        do {
            try await userService.updateWishlistOrder(userId: userId, orderedItems: orderedPerfumes)
            print("Orden de la Wishlist actualizado en el backend.")
             // Podríamos recargar aquí para asegurar consistencia: await loadWishlist()
        } catch {
            handleError("Error al actualizar el orden de la wishlist: \(error.localizedDescription)")
             self.wishlistPerfumes = previousOrder // Revertir UI si falla
        }
        isLoading = false
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
         print("🔴 UserViewModel Error: \(message)")
    }

    // MARK: - Data Integrity Check
    /// Check if user's tried perfumes and wishlist reference valid perfumes
    private func runDataIntegrityCheck() async {
        // Load all perfumes to build index if not already loaded
        do {
            let allPerfumes = try await perfumeService.fetchAllPerfumesOnce()

            // Build temporary index for checking - handle duplicate keys
            let perfumeIndex = allPerfumes.reduce(into: [String: Perfume]()) { dict, perfume in
                if dict[perfume.key] == nil {
                    dict[perfume.key] = perfume
                }
            }

            // Run integrity check
            let report = DataIntegrityChecker.checkUserDataIntegrity(
                triedPerfumes: triedPerfumes,
                wishlistItems: wishlistPerfumes,
                perfumeIndex: perfumeIndex
            )

            // Print report
            report.printReport()

            // If there are orphaned perfumes, clean them up automatically
            if report.orphanedPerfumes > 0 {
                print("⚠️ UserViewModel: Found \(report.orphanedPerfumes) orphaned perfume(s) in user data")
                print("   These perfumes exist in user records but not in the perfume database")
                print("   They may have been deleted or the perfumeKey is incorrect")

                // Auto-cleanup orphaned data
                await cleanOrphanedPerfumes(perfumeIndex: perfumeIndex)
            }
        } catch {
            print("⚠️ UserViewModel: Could not run data integrity check: \(error)")
        }
    }

    // MARK: - Auto-cleanup Orphaned Data
    /// Removes tried perfumes and wishlist items that reference non-existent perfumes
    private func cleanOrphanedPerfumes(perfumeIndex: [String: Perfume]) async {
        guard let userId = authViewModel.currentUser?.id else { return }

        print("🧹 Starting auto-cleanup of orphaned perfumes...")
        var cleanedCount = 0

        // Clean orphaned tried perfumes
        let orphanedTried = triedPerfumes.filter { perfumeIndex[$0.perfumeKey] == nil }
        for orphan in orphanedTried {
            guard let recordId = orphan.id else { continue }
            print("   🗑️ Removing orphaned tried perfume: \(orphan.perfumeKey)")
            do {
                try await userService.deleteTriedPerfumeRecord(userId: userId, recordId: recordId)
                cleanedCount += 1
            } catch {
                print("   ❌ Failed to remove tried perfume \(orphan.perfumeKey): \(error)")
            }
        }

        // Clean orphaned wishlist items
        let orphanedWishlist = wishlistPerfumes.filter { perfumeIndex[$0.perfumeKey] == nil }
        for orphan in orphanedWishlist {
            print("   🗑️ Removing orphaned wishlist item: \(orphan.perfumeKey)")
            do {
                try await userService.removeFromWishlist(userId: userId, wishlistItem: orphan)
                cleanedCount += 1
            } catch {
                print("   ❌ Failed to remove wishlist item \(orphan.perfumeKey): \(error)")
            }
        }

        if cleanedCount > 0 {
            print("✅ Auto-cleanup complete: Removed \(cleanedCount) orphaned item(s)")
            // Reload user data to reflect changes
            await loadTriedPerfumes()
            await loadWishlist()
        } else {
            print("ℹ️ No orphaned items to clean")
        }
    }
}
