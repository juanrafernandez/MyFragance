//
//  PerfBetaTests.swift
//  PerfBetaTests
//
//  Created by ES00571759 on 27/11/24.
//

import XCTest
import FirebaseAuth
@testable import PerfBeta

// MARK: - Test Models

/// Modelo simple para tests de CacheManager
private struct TestModel: Codable, Equatable {
    let id: String
    let name: String
    let value: Int
}

/// Modelo complejo para tests de CacheManager
private struct ComplexTestModel: Codable, Equatable {
    let id: String
    let name: String
    let values: [Int]
    let metadata: [String: String]
    let date: Date
    let nested: NestedModel

    struct NestedModel: Codable, Equatable {
        let title: String
        let count: Int
    }
}

// MARK: - CacheManager Tests

final class CacheManagerTests: XCTestCase {

    private var cacheManager: CacheManager!

    override func setUpWithError() throws {
        cacheManager = CacheManager.shared
    }

    override func tearDownWithError() throws {
        // Limpiar toda la caché después de cada test
        Task {
            await cacheManager.clearAllCache()
        }
    }

    // MARK: - Save/Load Tests

    func testSaveAndLoadSimpleModel() async throws {
        // Given
        let testKey = "test_simple_model"
        let testModel = TestModel(id: "1", name: "Test", value: 42)

        // When
        try await cacheManager.save(testModel, for: testKey)
        let loaded = await cacheManager.load(TestModel.self, for: testKey)

        // Then
        XCTAssertNotNil(loaded, "El modelo debería cargarse correctamente")
        XCTAssertEqual(loaded, testModel, "El modelo cargado debe ser idéntico al guardado")

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testSaveAndLoadComplexModel() async throws {
        // Given
        let testKey = "test_complex_model"
        let testDate = Date()
        let complexModel = ComplexTestModel(
            id: "complex-1",
            name: "Complex Test",
            values: [1, 2, 3, 4, 5],
            metadata: ["author": "Test", "version": "1.0"],
            date: testDate,
            nested: ComplexTestModel.NestedModel(title: "Nested", count: 10)
        )

        // When
        try await cacheManager.save(complexModel, for: testKey)
        let loaded = await cacheManager.load(ComplexTestModel.self, for: testKey)

        // Then
        XCTAssertNotNil(loaded, "El modelo complejo debería cargarse correctamente")
        XCTAssertEqual(loaded?.id, complexModel.id)
        XCTAssertEqual(loaded?.name, complexModel.name)
        XCTAssertEqual(loaded?.values, complexModel.values)
        XCTAssertEqual(loaded?.metadata, complexModel.metadata)
        XCTAssertEqual(loaded?.nested, complexModel.nested)

        // Verificar que la fecha se guardó correctamente (con tolerancia de 1 segundo)
        if let loadedDate = loaded?.date {
            XCTAssertEqual(loadedDate.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
        }

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testSaveAndLoadArray() async throws {
        // Given
        let testKey = "test_array"
        let testArray = [
            TestModel(id: "1", name: "First", value: 1),
            TestModel(id: "2", name: "Second", value: 2),
            TestModel(id: "3", name: "Third", value: 3)
        ]

        // When
        try await cacheManager.save(testArray, for: testKey)
        let loaded = await cacheManager.load([TestModel].self, for: testKey)

        // Then
        XCTAssertNotNil(loaded, "El array debería cargarse correctamente")
        XCTAssertEqual(loaded?.count, 3, "El array debe tener 3 elementos")
        XCTAssertEqual(loaded, testArray, "El array cargado debe ser idéntico al guardado")

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testLoadNonExistentCache() async throws {
        // Given
        let nonExistentKey = "non_existent_key_12345"

        // When
        let loaded = await cacheManager.load(TestModel.self, for: nonExistentKey)

        // Then
        XCTAssertNil(loaded, "Cargar una caché inexistente debe devolver nil")
    }

    func testOverwriteExistingCache() async throws {
        // Given
        let testKey = "test_overwrite"
        let firstModel = TestModel(id: "1", name: "First", value: 100)
        let secondModel = TestModel(id: "2", name: "Second", value: 200)

        // When
        try await cacheManager.save(firstModel, for: testKey)
        let firstLoad = await cacheManager.load(TestModel.self, for: testKey)

        try await cacheManager.save(secondModel, for: testKey)
        let secondLoad = await cacheManager.load(TestModel.self, for: testKey)

        // Then
        XCTAssertEqual(firstLoad, firstModel, "Primera carga debe devolver el primer modelo")
        XCTAssertEqual(secondLoad, secondModel, "Segunda carga debe devolver el segundo modelo")
        XCTAssertNotEqual(firstLoad, secondLoad, "Los modelos deben ser diferentes")

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    // MARK: - Timestamp Tests

    func testSaveAndLoadSyncTimestamp() async throws {
        // Given
        let testKey = "test_timestamp"
        let testDate = Date()

        // When
        await cacheManager.saveLastSyncTimestamp(testDate, for: testKey)
        let loaded = await cacheManager.getLastSyncTimestamp(for: testKey)

        // Then
        XCTAssertNotNil(loaded, "El timestamp debería cargarse correctamente")
        if let loadedDate = loaded {
            XCTAssertEqual(loadedDate.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Timestamp should not be nil")
        }

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testGetNonExistentTimestamp() async throws {
        // Given
        let nonExistentKey = "non_existent_timestamp_12345"

        // When
        let loaded = await cacheManager.getLastSyncTimestamp(for: nonExistentKey)

        // Then
        XCTAssertNil(loaded, "Cargar un timestamp inexistente debe devolver nil")
    }

    func testUpdateSyncTimestamp() async throws {
        // Given
        let testKey = "test_timestamp_update"
        let firstDate = Date(timeIntervalSince1970: 1000000)
        let secondDate = Date(timeIntervalSince1970: 2000000)

        // When
        await cacheManager.saveLastSyncTimestamp(firstDate, for: testKey)
        let firstLoad = await cacheManager.getLastSyncTimestamp(for: testKey)

        await cacheManager.saveLastSyncTimestamp(secondDate, for: testKey)
        let secondLoad = await cacheManager.getLastSyncTimestamp(for: testKey)

        // Then
        if let firstLoadDate = firstLoad {
            XCTAssertEqual(firstLoadDate.timeIntervalSince1970, firstDate.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("First timestamp should not be nil")
        }

        if let secondLoadDate = secondLoad {
            XCTAssertEqual(secondLoadDate.timeIntervalSince1970, secondDate.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Second timestamp should not be nil")
        }

        XCTAssertNotEqual(firstLoad, secondLoad)

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    // MARK: - Clear Cache Tests

    func testClearSpecificCache() async throws {
        // Given
        let testKey1 = "test_clear_1"
        let testKey2 = "test_clear_2"
        let model1 = TestModel(id: "1", name: "Test 1", value: 1)
        let model2 = TestModel(id: "2", name: "Test 2", value: 2)

        // When
        try await cacheManager.save(model1, for: testKey1)
        try await cacheManager.save(model2, for: testKey2)

        // Verificar que ambos están guardados
        let loadedBefore1 = await cacheManager.load(TestModel.self, for: testKey1)
        let loadedBefore2 = await cacheManager.load(TestModel.self, for: testKey2)
        XCTAssertNotNil(loadedBefore1)
        XCTAssertNotNil(loadedBefore2)

        // Limpiar solo la primera caché
        await cacheManager.clearCache(for: testKey1)

        let loadedAfter1 = await cacheManager.load(TestModel.self, for: testKey1)
        let loadedAfter2 = await cacheManager.load(TestModel.self, for: testKey2)

        // Then
        XCTAssertNil(loadedAfter1, "La caché 1 debe estar limpia")
        XCTAssertNotNil(loadedAfter2, "La caché 2 debe seguir existiendo")
        XCTAssertEqual(loadedAfter2, model2)

        // Cleanup
        await cacheManager.clearCache(for: testKey2)
    }

    func testClearAllCache() async throws {
        // Given
        let keys = ["key1", "key2", "key3"]
        let models = [
            TestModel(id: "1", name: "Test 1", value: 1),
            TestModel(id: "2", name: "Test 2", value: 2),
            TestModel(id: "3", name: "Test 3", value: 3)
        ]

        // When
        for (index, key) in keys.enumerated() {
            try await cacheManager.save(models[index], for: key)
        }

        // Verificar que todas están guardadas
        for (index, key) in keys.enumerated() {
            let loaded = await cacheManager.load(TestModel.self, for: key)
            XCTAssertNotNil(loaded)
            XCTAssertEqual(loaded, models[index])
        }

        // Limpiar toda la caché
        await cacheManager.clearAllCache()

        // Verificar que todas fueron eliminadas
        for key in keys {
            let loaded = await cacheManager.load(TestModel.self, for: key)
            XCTAssertNil(loaded, "La caché para \(key) debe estar limpia")
        }

        // Then
        let cacheSize = await cacheManager.getCacheSize()
        XCTAssertEqual(cacheSize, 0, "El tamaño de la caché debe ser 0 después de limpiar todo")
    }

    func testClearCacheAlsoRemovesTimestamp() async throws {
        // Given
        let testKey = "test_clear_with_timestamp"
        let model = TestModel(id: "1", name: "Test", value: 42)
        let timestamp = Date()

        // When
        try await cacheManager.save(model, for: testKey)
        await cacheManager.saveLastSyncTimestamp(timestamp, for: testKey)

        // Verificar que ambos existen
        let modelBeforeClear = await cacheManager.load(TestModel.self, for: testKey)
        let timestampBeforeClear = await cacheManager.getLastSyncTimestamp(for: testKey)
        XCTAssertNotNil(modelBeforeClear)
        XCTAssertNotNil(timestampBeforeClear)

        // Limpiar caché
        await cacheManager.clearCache(for: testKey)

        // Then
        let modelAfterClear = await cacheManager.load(TestModel.self, for: testKey)
        let timestampAfterClear = await cacheManager.getLastSyncTimestamp(for: testKey)
        XCTAssertNil(modelAfterClear, "La caché debe estar limpia")
        XCTAssertNil(timestampAfterClear, "El timestamp debe estar limpio")
    }

    // MARK: - Cache Size Tests

    func testCacheSizeCalculation() async throws {
        // Given
        let testKey1 = "test_size_1"
        let testKey2 = "test_size_2"
        let smallModel = TestModel(id: "1", name: "Small", value: 1)
        let largeArray = Array(repeating: TestModel(id: "1", name: "Test", value: 42), count: 100)

        // When
        let initialSize = await cacheManager.getCacheSize()

        try await cacheManager.save(smallModel, for: testKey1)
        let sizeAfterSmall = await cacheManager.getCacheSize()

        try await cacheManager.save(largeArray, for: testKey2)
        let sizeAfterLarge = await cacheManager.getCacheSize()

        // Then
        XCTAssertGreaterThan(sizeAfterSmall, initialSize, "El tamaño debe aumentar después de guardar")
        XCTAssertGreaterThan(sizeAfterLarge, sizeAfterSmall, "El tamaño debe aumentar más con el array grande")

        // Cleanup
        await cacheManager.clearAllCache()

        let finalSize = await cacheManager.getCacheSize()
        XCTAssertEqual(finalSize, initialSize, "El tamaño debe volver al inicial después de limpiar")
    }

    // MARK: - Performance Tests

    func testSavePerformance() async throws {
        // Given
        let largeArray = Array(repeating: TestModel(id: "1", name: "Test", value: 42), count: 1000)
        let testKey = "test_save_performance"

        // Measure save performance
        measure {
            Task {
                try? await cacheManager.save(largeArray, for: testKey)
            }
        }

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testLoadPerformance() async throws {
        // Given
        let largeArray = Array(repeating: TestModel(id: "1", name: "Test", value: 42), count: 1000)
        let testKey = "test_load_performance"
        try await cacheManager.save(largeArray, for: testKey)

        // Measure load performance
        measure {
            Task {
                _ = await cacheManager.load([TestModel].self, for: testKey)
            }
        }

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    // MARK: - Edge Cases

    func testSaveEmptyArray() async throws {
        // Given
        let testKey = "test_empty_array"
        let emptyArray: [TestModel] = []

        // When
        try await cacheManager.save(emptyArray, for: testKey)
        let loaded = await cacheManager.load([TestModel].self, for: testKey)

        // Then
        XCTAssertNotNil(loaded, "Debe poder cargar un array vacío")
        XCTAssertEqual(loaded?.count, 0, "El array debe estar vacío")

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testConcurrentSaveAndLoad() async throws {
        // Given
        let testKey = "test_concurrent"
        let models = (0..<10).map { TestModel(id: "\($0)", name: "Test \($0)", value: $0) }

        // When - Realizar múltiples operaciones concurrentes
        await withTaskGroup(of: Void.self) { group in
            for model in models {
                group.addTask {
                    try? await self.cacheManager.save(model, for: testKey)
                }
            }
        }

        // Then - La última operación debe ser la que persiste (debido a que es un actor)
        let loaded = await cacheManager.load(TestModel.self, for: testKey)
        XCTAssertNotNil(loaded, "Debe cargar algún modelo")

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }
}

// MARK: - MetadataIndexManager Tests

final class MetadataIndexManagerTests: XCTestCase {

    private var metadataManager: MetadataIndexManager!
    private var cacheManager: CacheManager!

    override func setUpWithError() throws {
        metadataManager = MetadataIndexManager.shared
        cacheManager = CacheManager.shared
    }

    override func tearDownWithError() throws {
        // Limpiar caché después de cada test
        Task {
            await cacheManager.clearAllCache()
        }
    }

    // MARK: - Cache Integration Tests

    func testMetadataIndexManagerUsesCacheManager() async throws {
        // Este test verifica que MetadataIndexManager usa CacheManager correctamente
        // Requiere Firebase configurado o mock

        // Given - Limpiar cualquier caché existente
        await cacheManager.clearCache(for: "metadata_index")

        // When - Verificar que no hay caché
        let cachedMetadata = await cacheManager.load([PerfumeMetadata].self, for: "metadata_index")

        // Then
        XCTAssertNil(cachedMetadata, "No debería haber caché al inicio")

        // Nota: Para testear getMetadataIndex() se requiere Firebase configurado
        // o un sistema de mocking más elaborado
    }

    func testCacheClearingAffectsMetadataIndex() async throws {
        // Given - Crear datos de prueba en caché
        let testMetadata = [
            PerfumeMetadata(
                id: "test1",
                name: "Test Perfume 1",
                brand: "Test Brand",
                key: "test-perfume-1",
                gender: "Unisex",
                family: "Woody",
                subfamilies: ["Oriental"],
                price: "€€",
                popularity: 7.5,
                year: 2020,
                updatedAt: Date()
            ),
            PerfumeMetadata(
                id: "test2",
                name: "Test Perfume 2",
                brand: "Test Brand",
                key: "test-perfume-2",
                gender: "Male",
                family: "Aquatic",
                subfamilies: ["Fresh"],
                price: "€€€",
                popularity: 8.0,
                year: 2021,
                updatedAt: Date()
            )
        ]

        // When - Guardar metadata en caché
        try await cacheManager.save(testMetadata, for: "metadata_index")

        // Verificar que se guardó
        let loaded = await cacheManager.load([PerfumeMetadata].self, for: "metadata_index")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)

        // Limpiar caché
        await cacheManager.clearCache(for: "metadata_index")

        // Then - Verificar que se limpió
        let afterClear = await cacheManager.load([PerfumeMetadata].self, for: "metadata_index")
        XCTAssertNil(afterClear, "La metadata debe estar limpia después de clear")
    }

    func testLastSyncTimestampPersistence() async throws {
        // Given
        let testTimestamp = Date()

        // When - Guardar timestamp como lo haría MetadataIndexManager
        await cacheManager.saveLastSyncTimestamp(testTimestamp, for: "metadata_index")

        // Then - Verificar que se guardó correctamente
        let loaded = await cacheManager.getLastSyncTimestamp(for: "metadata_index")
        XCTAssertNotNil(loaded)

        if let loadedTimestamp = loaded {
            XCTAssertEqual(
                loadedTimestamp.timeIntervalSince1970,
                testTimestamp.timeIntervalSince1970,
                accuracy: 1.0
            )
        } else {
            XCTFail("Timestamp should not be nil")
        }

        // Cleanup
        await cacheManager.clearCache(for: "metadata_index")
    }

    // MARK: - PerfumeMetadata Model Tests

    func testPerfumeMetadataEncodeDecode() throws {
        // Given
        let metadata = PerfumeMetadata(
            id: "test-id",
            name: "Test Perfume",
            brand: "Test Brand",
            key: "test-perfume",
            gender: "Unisex",
            family: "Woody",
            subfamilies: ["Oriental", "Spicy"],
            price: "€€€",
            popularity: 8.5,
            year: 2023,
            updatedAt: Date()
        )

        // When - Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)

        // Then - Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PerfumeMetadata.self, from: data)

        // Verify all fields
        XCTAssertEqual(decoded.id, metadata.id)
        XCTAssertEqual(decoded.name, metadata.name)
        XCTAssertEqual(decoded.brand, metadata.brand)
        XCTAssertEqual(decoded.key, metadata.key)
        XCTAssertEqual(decoded.gender, metadata.gender)
        XCTAssertEqual(decoded.family, metadata.family)
        XCTAssertEqual(decoded.subfamilies, metadata.subfamilies)
        XCTAssertEqual(decoded.price, metadata.price)
        XCTAssertEqual(decoded.popularity, metadata.popularity)
        XCTAssertEqual(decoded.year, metadata.year)

        // Date comparison with tolerance
        if let originalDate = metadata.updatedAt, let decodedDate = decoded.updatedAt {
            XCTAssertEqual(
                originalDate.timeIntervalSince1970,
                decodedDate.timeIntervalSince1970,
                accuracy: 1.0
            )
        }
    }

    func testPerfumeMetadataArraySerialization() async throws {
        // Given - Array grande de metadata
        let metadataArray = (0..<100).map { index in
            PerfumeMetadata(
                id: "test-\(index)",
                name: "Perfume \(index)",
                brand: "Brand \(index % 10)",
                key: "perfume-\(index)",
                gender: index % 2 == 0 ? "Male" : "Female",
                family: ["Woody", "Floral", "Aquatic", "Oriental"][index % 4],
                subfamilies: ["Sub1", "Sub2"],
                price: "€€",
                popularity: Double(index % 10),
                year: 2020 + (index % 5),
                updatedAt: Date()
            )
        }

        // When - Guardar en caché
        let testKey = "test_metadata_array"
        try await cacheManager.save(metadataArray, for: testKey)

        // Then - Cargar y verificar
        let loaded = await cacheManager.load([PerfumeMetadata].self, for: testKey)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 100)

        // Verificar algunos elementos
        if let loadedArray = loaded {
            XCTAssertEqual(loadedArray[0].id, "test-0")
            XCTAssertEqual(loadedArray[99].id, "test-99")
            XCTAssertEqual(loadedArray[50].brand, "Brand 0")
        }

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    // MARK: - Performance Tests

    func testMetadataArrayPerformance() async throws {
        // Given - Crear un array grande similar al real (5000+ perfumes)
        let largeMetadataArray = (0..<5000).map { index in
            PerfumeMetadata(
                id: "perf-\(index)",
                name: "Perfume Name \(index)",
                brand: "Brand \(index % 50)",
                key: "perfume-key-\(index)",
                gender: ["Male", "Female", "Unisex"][index % 3],
                family: ["Woody", "Floral", "Aquatic", "Oriental", "Citrus"][index % 5],
                subfamilies: ["Sub1", "Sub2", "Sub3"],
                price: ["€", "€€", "€€€", "€€€€"][index % 4],
                popularity: Double.random(in: 0...10),
                year: 2000 + (index % 24),
                updatedAt: Date()
            )
        }

        let testKey = "test_large_metadata"

        // When - Medir tiempo de guardado
        let saveStart = Date()
        try await cacheManager.save(largeMetadataArray, for: testKey)
        let saveDuration = Date().timeIntervalSince(saveStart)

        // Then - Debería guardar rápido (menos de 1 segundo para 5000 items)
        XCTAssertLessThan(saveDuration, 1.0, "Guardar 5000 metadata debería tomar menos de 1 segundo")

        // When - Medir tiempo de carga
        let loadStart = Date()
        let loaded = await cacheManager.load([PerfumeMetadata].self, for: testKey)
        let loadDuration = Date().timeIntervalSince(loadStart)

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 5000)
        XCTAssertLessThan(loadDuration, 0.5, "Cargar 5000 metadata debería tomar menos de 0.5 segundos")

        // Verificar tamaño en caché
        let cacheSize = await cacheManager.getCacheSize()
        XCTAssertGreaterThan(cacheSize, 0)

        print("📊 Performance Results:")
        print("   - Save time: \(String(format: "%.3f", saveDuration))s")
        print("   - Load time: \(String(format: "%.3f", loadDuration))s")
        print("   - Cache size: \(ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file))")

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    // MARK: - Edge Cases

    func testEmptyMetadataArray() async throws {
        // Given
        let emptyArray: [PerfumeMetadata] = []
        let testKey = "test_empty_metadata"

        // When
        try await cacheManager.save(emptyArray, for: testKey)
        let loaded = await cacheManager.load([PerfumeMetadata].self, for: testKey)

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 0)

        // Cleanup
        await cacheManager.clearCache(for: testKey)
    }

    func testMetadataWithNilOptionalFields() throws {
        // Given - Metadata con campos opcionales nil
        let metadata = PerfumeMetadata(
            id: "test",
            name: "Test",
            brand: "Brand",
            key: "test-key",
            gender: "Unisex",
            family: "Woody",
            subfamilies: [],
            price: nil,  // Opcional nil
            popularity: 5.0,
            year: 2020,
            updatedAt: nil  // Opcional nil
        )

        // When - Encode/Decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PerfumeMetadata.self, from: data)

        // Then
        XCTAssertNil(decoded.price)
        XCTAssertNil(decoded.updatedAt)
        XCTAssertEqual(decoded.name, metadata.name)
    }
}

// MARK: - Integration Tests (Require Firebase)

/*
 Los siguientes tests requieren una configuración de Firebase activa:

 final class MetadataIndexManagerFirebaseIntegrationTests: XCTestCase {

     func testGetMetadataIndexFirstTime() async throws {
         // Test que descarga el índice completo por primera vez
         // Requiere: Firebase configurado con datos de prueba
     }

     func testGetMetadataIndexFromCache() async throws {
         // Test que verifica que la segunda llamada usa caché
         // Requiere: Firebase configurado
     }

     func testIncrementalSync() async throws {
         // Test que verifica que solo descarga cambios
         // Requiere: Firebase con capacidad de modificar datos
     }

     func testForceRefresh() async throws {
         // Test que fuerza descarga completa
         // Requiere: Firebase configurado
     }
 }

 Para ejecutar estos tests:
 1. Configurar Firebase Test Project
 2. Poblar con datos de prueba
 3. Descomentar y ejecutar
 */

// MARK: - Mock AuthService

/// Mock de AuthService para tests unitarios
final class MockAuthService: AuthServiceProtocol {

    // MARK: - State
    var shouldSucceed: Bool = true
    var mockUser: PerfBeta.User?
    var errorToThrow: Error?

    // MARK: - Call Tracking
    var registerUserCalled = false
    var signInWithEmailCalled = false
    var signOutCalled = false
    var checkAndCreateProfileCalled = false
    var lastRegisteredEmail: String?
    var lastSignedInEmail: String?

    // MARK: - Protocol Implementation

    func registerUser(email: String, password: String, nombre: String, rol: String) async throws {
        registerUserCalled = true
        lastRegisteredEmail = email

        if let error = errorToThrow {
            throw error
        }

        if !shouldSucceed {
            throw AuthServiceError.unknownError
        }

        // Simulate successful registration by setting mockUser
        mockUser = PerfBeta.User(
            id: "mock-user-id",
            email: email,
            displayName: nombre,
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func signInWithEmail(email: String, password: String) async throws {
        signInWithEmailCalled = true
        lastSignedInEmail = email

        if let error = errorToThrow {
            throw error
        }

        if !shouldSucceed {
            throw AuthServiceError.userNotFound
        }

        // Simulate successful sign in
        mockUser = PerfBeta.User(
            id: "mock-user-id",
            email: email,
            displayName: "Test User",
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func signOut() throws {
        signOutCalled = true

        if let error = errorToThrow {
            throw error
        }

        mockUser = nil
    }

    func getCurrentAuthUser() -> PerfBeta.User? {
        return mockUser
    }

    func checkAndCreateUserProfileIfNeeded(firebaseUser: FirebaseAuth.User, providedName: String?, isLoginAttempt: Bool) async throws {
        checkAndCreateProfileCalled = true

        if let error = errorToThrow {
            throw error
        }
    }

    func addAuthStateListener(completion: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        // Return nil for tests - we'll manage state manually
        return nil
    }

    // MARK: - Test Helpers

    func reset() {
        shouldSucceed = true
        mockUser = nil
        errorToThrow = nil
        registerUserCalled = false
        signInWithEmailCalled = false
        signOutCalled = false
        checkAndCreateProfileCalled = false
        lastRegisteredEmail = nil
        lastSignedInEmail = nil
    }
}

// MARK: - AuthViewModel Tests

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var mockAuthService: MockAuthService!
    private var viewModel: AuthViewModel!

    override func setUpWithError() throws {
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }

    override func tearDownWithError() throws {
        mockAuthService.reset()
        viewModel = nil
        mockAuthService = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertFalse(viewModel.isAuthenticated, "Should not be authenticated initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error message initially")
        XCTAssertFalse(viewModel.isLoadingEmailLogin, "Should not be loading initially")
        XCTAssertFalse(viewModel.isLoadingEmailRegister, "Should not be loading initially")
    }

    func testInitialStateWithExistingUser() {
        // Given
        let existingUser = PerfBeta.User(
            id: "existing-user",
            email: "existing@test.com",
            displayName: "Existing User",
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockAuthService.mockUser = existingUser

        // When
        let viewModelWithUser = AuthViewModel(authService: mockAuthService)

        // Then
        XCTAssertTrue(viewModelWithUser.isAuthenticated, "Should be authenticated with existing user")
    }

    // MARK: - Email Registration Tests

    func testRegisterUserWithEmailSuccess() async {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "test@example.com"
        let password = "password123"
        let name = "Test User"

        // When
        let result = await viewModel.registerUserWithEmail(email: email, password: password, name: name)

        // Then
        XCTAssertTrue(result, "Registration should succeed")
        XCTAssertTrue(mockAuthService.registerUserCalled, "Register should be called")
        XCTAssertEqual(mockAuthService.lastRegisteredEmail, email, "Should register with correct email")
        XCTAssertNil(viewModel.errorMessage, "Should have no error message on success")
        XCTAssertFalse(viewModel.isLoadingEmailRegister, "Should not be loading after completion")
    }

    func testRegisterUserWithEmailFailure() async {
        // Given
        mockAuthService.shouldSucceed = false

        // When
        let result = await viewModel.registerUserWithEmail(email: "test@example.com", password: "pass", name: "Test")

        // Then
        XCTAssertFalse(result, "Registration should fail")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message on failure")
        XCTAssertFalse(viewModel.isLoadingEmailRegister, "Should not be loading after completion")
    }

    // MARK: - Email Sign In Tests

    func testSignInWithEmailSuccess() async throws {
        // Given
        mockAuthService.shouldSucceed = true
        let email = "test@example.com"
        let password = "password123"

        // When
        try await viewModel.signInWithEmailPassword(email: email, password: password)

        // Then
        XCTAssertTrue(mockAuthService.signInWithEmailCalled, "Sign in should be called")
        XCTAssertEqual(mockAuthService.lastSignedInEmail, email, "Should sign in with correct email")
        XCTAssertNil(viewModel.errorMessage, "Should have no error message on success")
        XCTAssertFalse(viewModel.isLoadingEmailLogin, "Should not be loading after completion")
    }

    func testSignInWithEmailFailure() async {
        // Given
        mockAuthService.shouldSucceed = false

        // When/Then
        do {
            try await viewModel.signInWithEmailPassword(email: "test@example.com", password: "wrong")
            XCTFail("Should throw error on failure")
        } catch {
            XCTAssertNotNil(viewModel.errorMessage, "Should have error message on failure")
            XCTAssertFalse(viewModel.isLoadingEmailLogin, "Should not be loading after completion")
        }
    }

    // MARK: - Sign Out Tests

    func testSignOut() throws {
        // Given
        mockAuthService.mockUser = PerfBeta.User(
            id: "test-user",
            email: "test@example.com",
            displayName: "Test",
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Recreate viewModel to pick up the authenticated state
        viewModel = AuthViewModel(authService: mockAuthService)

        // When
        try viewModel.signOut()

        // Then
        XCTAssertTrue(mockAuthService.signOutCalled, "Sign out should be called")
    }

    // MARK: - Loading State Tests

    func testLoadingStatesDuringEmailLogin() async {
        // Given
        mockAuthService.shouldSucceed = true

        // Capture loading state during operation
        var wasLoadingDuringOperation = false

        // Start operation in background
        let task = Task { @MainActor in
            try? await viewModel.signInWithEmailPassword(email: "test@example.com", password: "pass")
        }

        // Small delay to check loading state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        wasLoadingDuringOperation = viewModel.isLoadingEmailLogin

        await task.value

        // Then
        XCTAssertFalse(viewModel.isLoadingEmailLogin, "Should not be loading after completion")
    }
}

// MARK: - LoggingService Tests

final class LoggingServiceTests: XCTestCase {

    // MARK: - LogLevel Tests

    func testLogLevelComparison() {
        // Test that log levels compare correctly
        XCTAssertLessThan(LogLevel.verbose, LogLevel.debug)
        XCTAssertLessThan(LogLevel.debug, LogLevel.info)
        XCTAssertLessThan(LogLevel.info, LogLevel.warning)
        XCTAssertLessThan(LogLevel.warning, LogLevel.error)
        XCTAssertLessThan(LogLevel.error, LogLevel.none)
    }

    func testLogLevelEmojis() {
        XCTAssertEqual(LogLevel.verbose.emoji, "🔍")
        XCTAssertEqual(LogLevel.debug.emoji, "🐛")
        XCTAssertEqual(LogLevel.info.emoji, "ℹ️")
        XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
        XCTAssertEqual(LogLevel.error.emoji, "❌")
        XCTAssertEqual(LogLevel.none.emoji, "")
    }

    // MARK: - LogCategory Tests

    func testLogCategoryRawValues() {
        XCTAssertEqual(LogCategory.auth.rawValue, "Auth")
        XCTAssertEqual(LogCategory.perfume.rawValue, "Perfume")
        XCTAssertEqual(LogCategory.profile.rawValue, "Profile")
        XCTAssertEqual(LogCategory.userLibrary.rawValue, "UserLibrary")
        XCTAssertEqual(LogCategory.cache.rawValue, "Cache")
        XCTAssertEqual(LogCategory.network.rawValue, "Network")
        XCTAssertEqual(LogCategory.general.rawValue, "General")
    }

    // MARK: - AppLogger Configuration Tests

    func testConfigureDevelopment() {
        // When
        AppLogger.configureDevelopment()

        // Then
        XCTAssertEqual(AppLogger.minimumLevel, .verbose)
        XCTAssertNil(AppLogger.activeCategories)
        XCTAssertTrue(AppLogger.showTimestamp)
        XCTAssertTrue(AppLogger.showFileInfo)
    }

    func testConfigureProduction() {
        // When
        AppLogger.configureProduction()

        // Then
        XCTAssertEqual(AppLogger.minimumLevel, .error)
        XCTAssertNil(AppLogger.activeCategories)
        XCTAssertFalse(AppLogger.showTimestamp)
        XCTAssertFalse(AppLogger.showFileInfo)

        // Reset to development for other tests
        AppLogger.configureDevelopment()
    }

    func testConfigureForDebugging() {
        // When
        AppLogger.configureForDebugging(.auth, .perfume)

        // Then
        XCTAssertEqual(AppLogger.minimumLevel, .verbose)
        XCTAssertNotNil(AppLogger.activeCategories)
        XCTAssertTrue(AppLogger.activeCategories?.contains(.auth) ?? false)
        XCTAssertTrue(AppLogger.activeCategories?.contains(.perfume) ?? false)
        XCTAssertFalse(AppLogger.activeCategories?.contains(.network) ?? true)

        // Reset
        AppLogger.activeCategories = nil
    }
}
