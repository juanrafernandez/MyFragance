final class DependencyContainer {
    static let shared = DependencyContainer()

    lazy var perfumeService: PerfumeServiceProtocol = PerfumeService()
    lazy var brandService: BrandServiceProtocol = BrandService()
    lazy var familyService: FamilyServiceProtocol = FamilyService()
    lazy var notesService: NotesServiceProtocol = NotesService()
    lazy var perfumistService: PerfumistServiceProtocol = PerfumistService()
    lazy var questionsService: QuestionsServiceProtocol = QuestionsService()
    lazy var testService: TestServiceProtocol = TestService()
    lazy var olfactiveProfileService: OlfactiveProfileServiceProtocol = OlfactiveProfileService()
    lazy var userService: UserServiceProtocol = UserService()

    private init() {}
}
