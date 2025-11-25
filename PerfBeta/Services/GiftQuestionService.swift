import Foundation
import FirebaseFirestore

// MARK: - Gift Question Service Protocol
protocol GiftQuestionServiceProtocol {
    func loadQuestions() async throws -> [Question]
    func getQuestionsForFlow(_ flowType: String) async throws -> [Question]
    func getQuestion(byId id: String) async throws -> Question?
    func refreshQuestions() async throws -> [Question]
    #if DEBUG
    func addFlowB3Questions() async throws
    #endif
}

// MARK: - Gift Question Service
/// Servicio para cargar y cachear preguntas del flujo de regalo desde Firebase
actor GiftQuestionService: GiftQuestionServiceProtocol {

    static let shared = GiftQuestionService()

    private let db: Firestore
    private let cacheManager = CacheManager.shared
    private let cacheKey = "gift_questions_v2"  // ✅ Cambiada clave para forzar reload
    private let cacheVersionKey = "gift_questions_version_v2"  // ✅ Nueva clave de versión
    private let currentCacheVersion = 10  // ✅ Añadidas preguntas flowB4_03, flowB4_04, flowB4_05

    // Cache en memoria para acceso rápido
    private var questionsCache: [Question]?

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    /// Cargar preguntas (primero intenta desde cache, luego Firebase)
    func loadQuestions() async throws -> [Question] {
        // 1. Check memoria
        if let cached = questionsCache {
            #if DEBUG
            print("✅ [GiftQuestionService] Questions loaded from memory cache: \(cached.count)")
            #endif
            return cached
        }

        // 2. Check version del cache
        var cachedVersion = UserDefaults.standard.integer(forKey: cacheVersionKey)

        if cachedVersion != currentCacheVersion {
            #if DEBUG
            print("🔄 [GiftQuestionService] Cache version mismatch (cached: \(cachedVersion), current: \(currentCacheVersion)) - invalidating...")
            #endif

            // Invalidar cache antiguo
            await cacheManager.clearCache(for: cacheKey)
            questionsCache = nil

            // Actualizar versión
            UserDefaults.standard.set(currentCacheVersion, forKey: cacheVersionKey)
            cachedVersion = currentCacheVersion  // ✅ Actualizar variable local también

            #if DEBUG
            print("🔄 [GiftQuestionService] Cache invalidated, downloading fresh questions from Firebase...")
            #endif

            // Forzar descarga desde Firebase
            return try await downloadQuestions()
        }

        // 3. Check disco (solo si la versión es correcta)
        if let cachedQuestions = await cacheManager.load([Question].self, for: cacheKey) {
            #if DEBUG
            print("✅ [GiftQuestionService] Questions loaded from disk cache: \(cachedQuestions.count)")
            for q in cachedQuestions.filter({ $0.flowType == "B1" }) {
                print("   - B1 Question: \(q.id) (order: \(q.order))")
            }
            #endif
            questionsCache = cachedQuestions

            // Background sync para actualizar si hay cambios
            Task {
                try? await self.syncQuestionsInBackground()
            }

            return cachedQuestions
        }

        // 4. Download desde Firebase
        #if DEBUG
        print("📥 [GiftQuestionService] No cache found - fetching from Firebase...")
        #endif

        return try await downloadQuestions()
    }

    /// Obtener preguntas de un flujo específico
    func getQuestionsForFlow(_ flowType: String) async throws -> [Question] {
        let allQuestions = try await loadQuestions()

        // ✅ Usar el campo 'flow' en lugar de 'flowType'
        let filtered = allQuestions
            .filter { $0.flow == flowType }
            .sorted { $0.order < $1.order }

        #if DEBUG
        print("🔍 [GiftQuestionService] Questions for flow '\(flowType)': \(filtered.count)")
        #endif

        return filtered
    }

    /// Obtener pregunta específica por ID
    func getQuestion(byId id: String) async throws -> Question? {
        let allQuestions = try await loadQuestions()
        return allQuestions.first { $0.id == id }
    }

    /// Forzar actualización desde Firebase
    func refreshQuestions() async throws -> [Question] {
        #if DEBUG
        print("🔄 [GiftQuestionService] Force refresh from Firebase")
        #endif

        questionsCache = nil
        return try await downloadQuestions()
    }

    #if DEBUG
    /// ⚠️ FUNCIÓN TEMPORAL: Añadir preguntas B3 a Firebase (ejecutar solo una vez)
    func addFlowB3Questions() async throws {
        print("🚀 [DEBUG] Añadiendo preguntas del flujo B3 a Firebase...")

        let questionsData: [[String: Any]] = [
            // flowB3_02_intensity
            [
                "id": "flowB3_02_intensity",
                "order": 2,
                "flowType": "B3",
                "category": "intensity",
                "question": "¿Cómo le gustan los perfumes?",
                "description": "Define la intensidad y proyección preferida",
                "isConditional": true,
                "conditionalRules": [
                    "previousQuestion": "flowB3_01_aroma_types"
                ],
                "options": [
                    [
                        "id": "1",
                        "label": "Ligeros y sutiles",
                        "value": "light_subtle",
                        "description": "Se sienten cerca de la piel",
                        "filters": [
                            "intensity": ["low"],
                            "projection": ["low", "moderate"]
                        ]
                    ],
                    [
                        "id": "2",
                        "label": "Equilibrados",
                        "value": "balanced",
                        "description": "Se notan sin ser invasivos",
                        "filters": [
                            "intensity": ["medium"],
                            "projection": ["moderate"]
                        ]
                    ],
                    [
                        "id": "3",
                        "label": "Intensos y notorios",
                        "value": "intense_noticeable",
                        "description": "Con presencia y duración",
                        "filters": [
                            "intensity": ["high", "very_high"],
                            "projection": ["high", "explosive"],
                            "duration": ["long", "very_long"]
                        ]
                    ],
                    [
                        "id": "4",
                        "label": "Varía según la ocasión",
                        "value": "varies",
                        "description": "A veces suave, a veces intenso",
                        "filters": [
                            "intensity": NSNull()
                        ]
                    ]
                ],
                "uiConfig": [
                    "displayType": "single_choice",
                    "showDescriptions": true,
                    "isMultipleSelection": false
                ],
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],

            // flowB3_03_moment
            [
                "id": "flowB3_03_moment",
                "order": 3,
                "flowType": "B3",
                "category": "moment_use",
                "question": "¿Cuándo usa principalmente perfume?",
                "description": "Identifica el momento principal de uso",
                "isConditional": true,
                "conditionalRules": [
                    "previousQuestion": "flowB3_02_intensity"
                ],
                "options": [
                    [
                        "id": "1",
                        "label": "Durante el día",
                        "value": "daytime",
                        "description": "Trabajo, actividades diarias",
                        "filters": [
                            "occasions": ["daily_use", "office", "sunny_days"],
                            "season_bonus": ["spring", "summer"]
                        ]
                    ],
                    [
                        "id": "2",
                        "label": "Por la noche",
                        "value": "nighttime",
                        "description": "Salidas, eventos, cenas",
                        "filters": [
                            "occasions": ["nights", "dates", "parties"],
                            "season_bonus": ["autumn", "winter"]
                        ]
                    ],
                    [
                        "id": "3",
                        "label": "Fines de semana",
                        "value": "weekends",
                        "description": "Tiempo libre, actividades casuales",
                        "filters": [
                            "occasions": ["social_events", "nature_walks", "beach_days"]
                        ]
                    ],
                    [
                        "id": "4",
                        "label": "En toda ocasión",
                        "value": "all_occasions",
                        "description": "Uso versátil diario",
                        "filters": [
                            "occasions": ["daily_use", "social_events"],
                            "versatility_bonus": true
                        ]
                    ]
                ],
                "uiConfig": [
                    "displayType": "single_choice",
                    "showDescriptions": true,
                    "isMultipleSelection": false
                ],
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],

            // flowB3_04_personal_style
            [
                "id": "flowB3_04_personal_style",
                "order": 4,
                "flowType": "B3",
                "category": "personal_style",
                "question": "¿Cuál es su estilo personal?",
                "description": "Define su personalidad y estilo",
                "isConditional": true,
                "conditionalRules": [
                    "previousQuestion": "flowB3_03_moment"
                ],
                "options": [
                    [
                        "id": "1",
                        "label": "Clásico y elegante",
                        "value": "classic_elegant",
                        "filters": [
                            "personalities": ["elegant"],
                            "families_bonus": ["floral", "woody"],
                            "year_preference": "timeless"
                        ]
                    ],
                    [
                        "id": "2",
                        "label": "Moderno y trendy",
                        "value": "modern_trendy",
                        "filters": [
                            "personalities": ["dynamic", "confident"],
                            "families_bonus": ["fruity", "gourmand"],
                            "year": ">=2018"
                        ]
                    ],
                    [
                        "id": "3",
                        "label": "Natural y relajado",
                        "value": "natural_relaxed",
                        "filters": [
                            "personalities": ["relaxed"],
                            "families_bonus": ["green", "aquatic", "citrus"],
                            "intensity": ["low", "medium"]
                        ]
                    ],
                    [
                        "id": "4",
                        "label": "Sofisticado y misterioso",
                        "value": "sophisticated_mysterious",
                        "filters": [
                            "personalities": ["mysterious", "passionate"],
                            "families_bonus": ["oriental", "woody", "spicy"],
                            "intensity": ["high", "very_high"]
                        ]
                    ],
                    [
                        "id": "5",
                        "label": "Divertido y espontáneo",
                        "value": "fun_spontaneous",
                        "filters": [
                            "personalities": ["fun", "adventurous"],
                            "families_bonus": ["fruity", "citrus", "floral"],
                            "projection": ["moderate", "high"]
                        ]
                    ]
                ],
                "uiConfig": [
                    "displayType": "single_choice",
                    "showDescriptions": false,
                    "isMultipleSelection": false
                ],
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ],

            // flowB3_05_budget
            [
                "id": "flowB3_05_budget",
                "order": 5,
                "flowType": "B3",
                "category": "budget",
                "question": "¿Cuál es tu presupuesto aproximado?",
                "description": "Define el rango de precio",
                "isConditional": true,
                "conditionalRules": [
                    "previousQuestion": "flowB3_04_personal_style"
                ],
                "options": [
                    [
                        "id": "1",
                        "label": "Económico (hasta 50€)",
                        "value": "budget_low",
                        "filters": [
                            "price": ["€"]
                        ]
                    ],
                    [
                        "id": "2",
                        "label": "Medio (50€ - 100€)",
                        "value": "budget_medium",
                        "filters": [
                            "price": ["€", "€€"]
                        ]
                    ],
                    [
                        "id": "3",
                        "label": "Alto (100€ - 200€)",
                        "value": "budget_high",
                        "filters": [
                            "price": ["€€", "€€€"]
                        ]
                    ],
                    [
                        "id": "4",
                        "label": "Premium (más de 200€)",
                        "value": "budget_premium",
                        "filters": [
                            "price": ["€€€", "€€€€"]
                        ]
                    ],
                    [
                        "id": "5",
                        "label": "Sin límite específico",
                        "value": "budget_any",
                        "filters": [
                            "price": NSNull()
                        ]
                    ]
                ],
                "uiConfig": [
                    "displayType": "single_choice",
                    "showDescriptions": false,
                    "isMultipleSelection": false
                ],
                "createdAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date())
            ]
        ]

        // Añadir cada pregunta a Firebase
        for questionData in questionsData {
            guard let questionId = questionData["id"] as? String else {
                print("❌ Error: No se pudo obtener el ID de la pregunta")
                continue
            }

            print("📝 Añadiendo pregunta: \(questionId)")

            try await db.collection("questions_es")
                .document(questionId)
                .setData(questionData)

            print("✅ Pregunta \(questionId) añadida correctamente")
        }

        print("✨ Todas las preguntas B3 añadidas correctamente")
        print("🔄 Invalidando cache...")

        // Invalidar cache para forzar recarga
        questionsCache = nil
        await cacheManager.clearCache(for: cacheKey)

        print("✅ Cache invalidado - las preguntas se cargarán en el próximo refresh")
    }
    #endif

    // MARK: - Private Methods

    private func downloadQuestions() async throws -> [Question] {
        // ✅ Cargar desde questions_es filtrando por category = "category_gift"
        let snapshot = try await db.collection("questions_es")
            .whereField("category", isEqualTo: "category_gift")
            .order(by: "order")
            .getDocuments()

        #if DEBUG
        print("📥 [GiftQuestionService] Firestore returned \(snapshot.documents.count) documents")
        #endif

        var questions: [Question] = []
        for doc in snapshot.documents {
            do {
                let question = try doc.data(as: Question.self)
                questions.append(question)
            } catch {
                #if DEBUG
                print("❌ [GiftQuestionService] Failed to decode question '\(doc.documentID)': \(error)")
                #endif
            }
        }

        guard !questions.isEmpty else {
            throw GiftQuestionServiceError.noQuestionsFound
        }

        #if DEBUG
        print("✅ [GiftQuestionService] Downloaded \(questions.count) questions from Firebase (questions_es)")

        // Mostrar resumen por flujo
        let flowTypes = ["main", "A", "B1", "B2", "B3", "B4"]
        for flowType in flowTypes {
            let flowQuestions = questions.filter { $0.flowType == flowType }.sorted { $0.order < $1.order }
            if !flowQuestions.isEmpty {
                print("   \(flowType) Questions: \(flowQuestions.count)")
                for q in flowQuestions {
                    print("     - \(q.id) (order: \(q.order))")
                }
            }
        }
        #endif

        // Guardar en cache
        await saveToCache(questions)

        // Guardar en memoria
        questionsCache = questions

        return questions
    }

    private func syncQuestionsInBackground() async throws {
        // Obtener última sincronización
        let lastSync = await cacheManager.getLastSyncTimestamp(for: cacheKey) ?? Date.distantPast

        // ✅ Consultar solo preguntas modificadas con category = "category_gift"
        let snapshot = try await db.collection("questions_es")
            .whereField("category", isEqualTo: "category_gift")
            .whereField("updatedAt", isGreaterThan: Timestamp(date: lastSync))
            .getDocuments()

        guard !snapshot.documents.isEmpty else {
            #if DEBUG
            print("✅ [GiftQuestionService] No updates needed")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [GiftQuestionService] Found \(snapshot.documents.count) updated questions")
        #endif

        // Descargar todas las preguntas actualizadas
        let updatedQuestions = try await downloadQuestions()

        #if DEBUG
        print("✅ [GiftQuestionService] Background sync complete: \(updatedQuestions.count) questions")
        #endif
    }

    private func saveToCache(_ questions: [Question]) async {
        do {
            try await cacheManager.save(questions, for: cacheKey)
            await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)

            #if DEBUG
            print("💾 [GiftQuestionService] Questions saved to cache: \(questions.count)")
            #endif
        } catch {
            #if DEBUG
            print("❌ [GiftQuestionService] Failed to save to cache: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Gift Profile Service Protocol
protocol GiftProfileServiceProtocol {
    func saveProfile(_ profile: GiftProfile, userId: String) async throws
    func loadProfiles(userId: String) async throws -> [GiftProfile]
    func loadProfile(id: String, userId: String) async throws -> GiftProfile?
    func updateProfile(_ profile: GiftProfile, userId: String) async throws
    func deleteProfile(id: String, userId: String) async throws
    func updateOrderIndices(_ profiles: [GiftProfile], userId: String) async throws
}

// MARK: - Gift Profile Service
/// Servicio para gestionar perfiles de regalo guardados
actor GiftProfileService: GiftProfileServiceProtocol {

    static let shared = GiftProfileService()

    private let db: Firestore
    private let cacheManager = CacheManager.shared

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func saveProfile(_ profile: GiftProfile, userId: String) async throws {
        let profileData = profile.toFirestore()

        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(profile.id)
            .setData(profileData)

        #if DEBUG
        print("✅ [GiftProfileService] Profile saved: \(profile.id)")
        #endif

        // Invalidar cache de perfiles
        await invalidateProfilesCache(userId: userId)
    }

    func loadProfiles(userId: String) async throws -> [GiftProfile] {
        // Check cache primero
        // v2: Added orderIndex field for custom ordering
        let cacheKey = "gift_profiles_v2_\(userId)"
        if let cached = await cacheManager.load([GiftProfile].self, for: cacheKey) {
            #if DEBUG
            print("✅ [GiftProfileService] Profiles loaded from cache: \(cached.count)")
            #endif
            // Ordenar por orderIndex
            return cached.sorted { $0.orderIndex < $1.orderIndex }
        }

        // Download desde Firebase
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .order(by: "orderIndex")  // ✅ Ordenar por orderIndex en lugar de lastUsed
            .getDocuments()

        let profiles = snapshot.documents.compactMap { doc -> GiftProfile? in
            GiftProfile.fromFirestore(doc.data())
        }

        #if DEBUG
        print("✅ [GiftProfileService] Profiles loaded from Firebase: \(profiles.count)")
        #endif

        // Guardar en cache
        try? await cacheManager.save(profiles, for: cacheKey)

        return profiles
    }

    func loadProfile(id: String, userId: String) async throws -> GiftProfile? {
        let doc = try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(id)
            .getDocument()

        guard doc.exists, let data = doc.data() else {
            return nil
        }

        return GiftProfile.fromFirestore(data)
    }

    func updateProfile(_ profile: GiftProfile, userId: String) async throws {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        let profileData = updatedProfile.toFirestore()

        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(profile.id)
            .updateData(profileData)

        #if DEBUG
        print("✅ [GiftProfileService] Profile updated: \(profile.id)")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    func deleteProfile(id: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(id)
            .delete()

        #if DEBUG
        print("✅ [GiftProfileService] Profile deleted: \(id)")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    func updateOrderIndices(_ profiles: [GiftProfile], userId: String) async throws {
        // Batch update para eficiencia
        let batch = db.batch()

        for (index, profile) in profiles.enumerated() {
            var updatedProfile = profile
            updatedProfile.orderIndex = index
            updatedProfile.updatedAt = Date()

            let ref = db.collection("users")
                .document(userId)
                .collection("giftProfiles")
                .document(profile.id)

            batch.updateData(["orderIndex": index, "updatedAt": Timestamp(date: Date())], forDocument: ref)
        }

        try await batch.commit()

        #if DEBUG
        print("✅ [GiftProfileService] Order indices updated for \(profiles.count) profiles")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    // MARK: - Private Methods

    private func invalidateProfilesCache(userId: String) async {
        // v2: Added orderIndex field for custom ordering
        let cacheKey = "gift_profiles_v2_\(userId)"
        await cacheManager.clearCache(for: cacheKey)
        #if DEBUG
        print("🗑️ [GiftProfileService] Cache invalidated for user: \(userId)")
        #endif
    }
}

// MARK: - Errors
enum GiftQuestionServiceError: LocalizedError {
    case noQuestionsFound
    case questionNotFound(String)
    case invalidFlowType(String)

    var errorDescription: String? {
        switch self {
        case .noQuestionsFound:
            return "No se encontraron preguntas en Firebase"
        case .questionNotFound(let id):
            return "Pregunta no encontrada: \(id)"
        case .invalidFlowType(let flow):
            return "Tipo de flujo inválido: \(flow)"
        }
    }
}
