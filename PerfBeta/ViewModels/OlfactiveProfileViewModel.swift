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
    private let appState: AppState

    private var listenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private var currentListenerUserId: String?
    private var currentListenerLanguage: String?

    init(
        olfactiveProfileService: OlfactiveProfileServiceProtocol,
        authViewModel: AuthViewModel,
        appState: AppState = AppState.shared
    ) {
        self.olfactiveProfileService = olfactiveProfileService
        self.authViewModel = authViewModel
        self.appState = appState
        #if DEBUG
        print("OlfactiveProfileViewModel initialized.")
        #endif

        Publishers.CombineLatest(authViewModel.$currentUser, appState.$language)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates(by: { prev, curr in
                // Evitar configurar el listener si userId y language no han cambiado
                prev.0?.id == curr.0?.id && prev.1 == curr.1
            })
            .sink { [weak self] (user, language) in
                guard let self = self else { return }
                if let userId = user?.id, !userId.isEmpty {
                    self.setupListenerOrFetchData(userId: userId, language: language)
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

    private func setupListenerOrFetchData(userId: String, language: String) {
        // ✅ Evitar configurar listener duplicado si ya está activo para el mismo user/language
        if currentListenerUserId == userId && currentListenerLanguage == language {
            #if DEBUG
            print("OlfactiveProfileViewModel: Listener already active for user \(userId), lang \(language). Skipping setup.")
            #endif
            return
        }

        guard !isLoading else { return }
        self.isLoading = true
        self.errorMessage = nil
        listenerRegistration?.remove()

        currentListenerUserId = userId
        currentListenerLanguage = language

        #if DEBUG
        print("OlfactiveProfileViewModel: Setting up listener for user \(userId), lang \(language)")
        #endif
        listenerRegistration = olfactiveProfileService.listenToProfilesChanges(userId: userId, language: language) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            self.hasAttemptedLoad = true  // ✅ Marcar que se intentó cargar
            switch result {
            case .success(let fetchedProfiles):
                self.profiles = fetchedProfiles
                self.errorMessage = nil
            case .failure(let error):
                 if self.authViewModel.currentUser != nil {
                     self.errorMessage = "Error al escuchar perfiles: \(error.localizedDescription)"
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
         currentListenerLanguage = nil
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
        let currentLanguage = appState.language
        isLoading = true
        errorMessage = nil
        do {
            try await olfactiveProfileService.addProfile(userId: userId, language: currentLanguage, profile: newProfileData)
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
        let currentLanguage = appState.language
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
            try await olfactiveProfileService.updateProfile(userId: userId, language: currentLanguage, profile: profile)
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
        let currentLanguage = appState.language
        isLoading = true
        errorMessage = nil

        let originalProfiles = profiles
        profiles.removeAll { $0.id == profileId }

        do {
            try await olfactiveProfileService.deleteProfile(userId: userId, language: currentLanguage, profile: profile)
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
         let currentLanguage = appState.language

         let previousOrder = self.profiles
         self.profiles = newOrderedProfiles
         isLoading = true
         errorMessage = nil

         do {
             try await olfactiveProfileService.updateProfilesOrder(userId: userId, language: currentLanguage, orderedProfiles: newOrderedProfiles)
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
