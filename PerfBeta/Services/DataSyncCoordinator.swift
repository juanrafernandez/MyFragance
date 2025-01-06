import SwiftData

class DataSyncCoordinator {
    private let perfumeService: PerfumeService
    private let familiaOlfativaService: FamiliaOlfativaService

    init(modelContext: ModelContext) {
        self.perfumeService = PerfumeService(modelContext: modelContext)
        self.familiaOlfativaService = FamiliaOlfativaService(modelContext: modelContext)
    }

    func startListening() {
        perfumeService.startListeningToPerfumes()
        familiaOlfativaService.startListeningToFamiliasOlfativas()
    }

    func stopListening() {
        perfumeService.stopListeningToPerfumes()
        familiaOlfativaService.stopListeningToFamiliasOlfativas()
    }
}
