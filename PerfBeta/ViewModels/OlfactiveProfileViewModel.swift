import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
public final class OlfactiveProfileViewModel: ObservableObject {
    @Published var profiles: [OlfactiveProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // ✅ FIX: Flag para distinguir "nunca cargado" de "cargado y vacío"
    @Published private(set) var hasAttemptedLoad: Bool = false

    private let olfactiveProfileService: OlfactiveProfileServiceProtocol
    private let authViewModel: AuthViewModel

    private var listenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private var currentListenerUserId: String?

    // ✅ NEW: Flag para evitar clear prematuro durante inicialización
    private var hasReceivedInitialAuthState: Bool = false

    init(
        olfactiveProfileService: OlfactiveProfileServiceProtocol,
        authViewModel: AuthViewModel,
        appState: AppState = AppState.shared
    ) {
        self.olfactiveProfileService = olfactiveProfileService
        self.authViewModel = authViewModel
        #if DEBUG
        print("OlfactiveProfileViewModel initialized.")
        #endif

        // ✅ FIX: Esperar a que el auth check inicial complete antes de reaccionar a cambios
        authViewModel.$isCheckingInitialAuth
            .filter { !$0 } // Solo cuando termine el check inicial
            .first() // Solo la primera vez
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.hasReceivedInitialAuthState = true
                #if DEBUG
                print("OlfactiveProfileViewModel: Initial auth check completed, setting up reactive listener")
                #endif

                // ✅ FIX CRÍTICO: Configurar listener inmediatamente si ya hay usuario autenticado
                // Esto resuelve la condición de carrera cuando el usuario ya está autenticado desde el inicio
                if let userId = self.authViewModel.currentUser?.id, !userId.isEmpty {
                    #if DEBUG
                    print("OlfactiveProfileViewModel: User already authenticated, setting up listener immediately")
                    #endif
                    self.setupListenerOrFetchData(userId: userId)
                }
            }
            .store(in: &cancellables)

        // Solo escuchar cambios de usuario (ya no dependemos de language)
        authViewModel.$currentUser
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates(by: { prev, curr in
                prev?.id == curr?.id
            })
            .sink { [weak self] user in
                guard let self = self else { return }

                // ✅ FIX: NO actuar hasta que el auth check inicial haya completado
                guard self.hasReceivedInitialAuthState else {
                    #if DEBUG
                    print("OlfactiveProfileViewModel: Ignoring auth update (initial check not complete)")
                    #endif
                    return
                }

                if let userId = user?.id, !userId.isEmpty {
                    self.setupListenerOrFetchData(userId: userId)
                } else {
                    self.clearDataAndListener()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        listenerRegistration?.remove()
        #if DEBUG
        print("OlfactiveProfileViewModel deinitialized.")
        #endif
    }

    private func setupListenerOrFetchData(userId: String) {
        // ✅ Evitar configurar listener duplicado si ya está activo para el mismo user
        if currentListenerUserId == userId {
            #if DEBUG
            print("OlfactiveProfileViewModel: Listener already active for user \(userId). Skipping setup.")
            #endif
            return
        }

        guard !isLoading else { return }
        self.isLoading = true
        self.errorMessage = nil
        listenerRegistration?.remove()

        currentListenerUserId = userId

        // ✅ FIX CRÍTICO: Marcar hasAttemptedLoad INMEDIATAMENTE al configurar listener
        // Esto evita que HomeTabView se quede stuck en skeleton
        self.hasAttemptedLoad = true

        #if DEBUG
        print("🔵 [OlfactiveProfileViewModel] Setting up listener for user \(userId)")
        print("🔵 [OlfactiveProfileViewModel] hasAttemptedLoad = true (before listener response)")
        #endif
        listenerRegistration = olfactiveProfileService.listenToProfilesChanges(userId: userId) { [weak self] result in
            guard let self = self else { return }

            // ✅ CRÍTICO: Asegurar que las actualizaciones @Published ocurran en el main thread
            Task { @MainActor in
                self.isLoading = false
                self.hasAttemptedLoad = true  // ✅ Marcar que se intentó cargar

                switch result {
                case .success(let fetchedProfiles):
                    #if DEBUG
                    print("🎯 [OlfactiveProfileViewModel] Listener actualizó profiles: \(fetchedProfiles.count) perfiles")
                    #endif
                    self.profiles = fetchedProfiles
                    self.errorMessage = nil
                case .failure(let error):
                     if self.authViewModel.currentUser != nil {
                         self.errorMessage = "Error al escuchar perfiles: \(error.localizedDescription)"
                     }
                }
            }
        }
        if listenerRegistration == nil {
             self.isLoading = false
        }
    }

    private func clearDataAndListener() {
         listenerRegistration?.remove()
         listenerRegistration = nil
         currentListenerUserId = nil
         profiles = []
         isLoading = false
         hasAttemptedLoad = false  // ✅ Resetear flag de carga
         errorMessage = nil
         #if DEBUG
         print("OlfactiveProfileViewModel: Listener stopped and data cleared.")
         #endif
    }

    func addProfile(newProfileData: OlfactiveProfile) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Debes iniciar sesión.")
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await olfactiveProfileService.addProfile(userId: userId, profile: newProfileData)
        } catch {
            handleError("Error al añadir perfil: \(error.localizedDescription)")
        }
        isLoading = false
    }

     func updateProfile(profile: OlfactiveProfile) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Debes iniciar sesión.")
            return
        }
         guard profile.id != nil else {
             handleError("Error: Perfil sin ID.")
             return
         }
        isLoading = true
        errorMessage = nil

        let originalProfileIndex = profiles.firstIndex(where: { $0.id == profile.id })
        let originalProfile = originalProfileIndex.flatMap { profiles[$0] }
        if let index = originalProfileIndex {
            var updatedProfile = profile
            updatedProfile.orderIndex = profiles[index].orderIndex
            profiles[index] = updatedProfile
        }

        do {
            try await olfactiveProfileService.updateProfile(userId: userId, profile: profile)
        } catch {
            handleError("Error al actualizar perfil: \(error.localizedDescription)")
            if let index = originalProfileIndex, let oldProfile = originalProfile {
                profiles[index] = oldProfile
            }
        }
        isLoading = false
    }

    func deleteProfile(profile: OlfactiveProfile) async {
        guard let userId = authViewModel.currentUser?.id else {
            handleError("Debes iniciar sesión.")
            return
        }
         guard let profileId = profile.id else {
             handleError("Error: Perfil sin ID.")
             return
         }
        isLoading = true
        errorMessage = nil

        let originalProfiles = profiles
        profiles.removeAll { $0.id == profileId }

        do {
            try await olfactiveProfileService.deleteProfile(userId: userId, profile: profile)
        } catch {
            handleError("Error al eliminar perfil: \(error.localizedDescription)")
            profiles = originalProfiles
        }
        isLoading = false
    }

     func updateOrder(newOrderedProfiles: [OlfactiveProfile]) async {
         guard let userId = authViewModel.currentUser?.id else {
             handleError("Debes iniciar sesión.")
             return
         }

         let previousOrder = self.profiles
         self.profiles = newOrderedProfiles
         isLoading = true
         errorMessage = nil

         do {
             try await olfactiveProfileService.updateProfilesOrder(userId: userId, orderedProfiles: newOrderedProfiles)
         } catch {
             handleError("Error al guardar el nuevo orden: \(error.localizedDescription)")
             self.profiles = previousOrder
         }
          isLoading = false
     }

    private func handleError(_ message: String) {
        errorMessage = message
        #if DEBUG
        print("🔴 OlfactiveProfileViewModel Error: \(message)")
        #endif
    }
}
