import XCTest
@testable import PerfBeta

class QuizViewModelTests: XCTestCase {

    func testCalculateProfile() throws {
        // Instancia de ViewModel
        let viewModel = QuizViewModel()
        viewModel.answers = ["Cítricas", "Florales", "Cítricas"]

        // Calcula el perfil
        let profile = viewModel.calculateProfile()

        // Verifica los resultados
        let citrusPercentage = try XCTUnwrap(profile["Cítricas"])
        XCTAssertEqual(citrusPercentage, 66.67, accuracy: 0.01, "El porcentaje para 'Cítricas' no coincide.")

        let floralPercentage = try XCTUnwrap(profile["Florales"])
        XCTAssertEqual(floralPercentage, 33.33, accuracy: 0.01, "El porcentaje para 'Florales' no coincide.")

        let woodyPercentage = profile["Amaderadas"] ?? 0
        XCTAssertEqual(woodyPercentage, 0, accuracy: 0.01, "El porcentaje para 'Amaderadas' debería ser 0.")
    }
}
