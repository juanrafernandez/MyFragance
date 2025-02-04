import Foundation
import Combine
import SwiftUI

@MainActor
public final class NotesViewModel: ObservableObject {
    @Published var notes: [Notes] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    let notesService: NotesServiceProtocol

    // MARK: - Inicialización con Dependencias Inyectadas
    init(
        notesService: NotesServiceProtocol = DependencyContainer.shared.notesService
    ) {
        self.notesService = notesService
    }

    // MARK: - Cargar Datos Iniciales
    func loadInitialData() async {
        isLoading = true
        do {
            notes = try await notesService.fetchNotes()
            print("Notas cargadas exitosamente. Total: \(notes.count)")
            // Iniciar la escucha de cambios en tiempo real
            startListeningToNotes()
        } catch {
            handleError("Error al cargar notas: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    func startListeningToNotes() {
        notesService.listenToNotesChanges { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedNotes):
                    self?.notes = updatedNotes
                case .failure(let error):
                    self?.errorMessage = IdentifiableString(value: "Error al escuchar cambios: \(error.localizedDescription)")
                }
            }
        }
    }
}
