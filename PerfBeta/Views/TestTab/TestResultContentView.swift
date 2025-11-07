import SwiftUI

struct TestResultContentView: View {
    let profile: OlfactiveProfile

    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel

    @State private var isAccordionExpanded = false
    @State private var selectedPerfume: Perfume?
    @State private var selectedBrandForPerfume: Brand?

    @State private var relatedPerfumes: [(perfume: Perfume, score: Double)] = []
    @State private var isLoadingRelated = false
    @State private var errorMessage: IdentifiableString?

    @State private var isPresentingAllPerfumes = false
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        profileHeader
                        recommendedPerfumesView
                        testSummary(proxy: proxy)
                    }
                    .padding(.horizontal, 16) // Añadir padding horizontal
                }
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                // PerfumeDetailView puede funcionar con brand = nil
                PerfumeDetailView(
                    perfume: perfume,
                    brand: selectedBrandForPerfume, // nil si no se encuentra
                    profile: profile // Pasar el perfil aquí
                )
                .overlay {
                    if isLoadingRelated {
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
            .task(id: selectedPerfume) {
                await loadRelatedPerfumes()
            }
            .onChange(of: selectedPerfume) {
                if let perfume = selectedPerfume {
                    selectedBrandForPerfume = brandViewModel.getBrand(byKey: perfume.brand)
                } else {
                    selectedBrandForPerfume = nil
                }
            }
        }
    }

    // MARK: - Subviews

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Perfil Olfativo")
                .font(.headline)
                .foregroundColor(Color(hex: "#2D3748"))
                .padding(.top, 16)
                .padding(.leading, 16)

            TestProfileHeaderView(profile: profile)
        }
    }

    private func loadRelatedPerfumes() async {
        #if DEBUG
        print("loadRelatedPerfumes called") // Debug print
        #endif

        isLoadingRelated = true
        errorMessage = nil

        do {
            #if DEBUG
            print("Attempting to fetch related perfumes") // Debug print
            #endif

            // CORRECTED LINE: Use 'from:' instead of 'families:'
            relatedPerfumes = try await perfumeViewModel.getRelatedPerfumes(
                for: profile,
                from: familyViewModel.familias // Correct label is 'from'
                // loadMore: false // You can omit this, as it defaults to false
            )

            #if DEBUG
            print("Successfully fetched related perfumes: \(relatedPerfumes.count)") // Debug print
            #endif
        } catch {
            errorMessage = IdentifiableString(value: "Error al cargar perfumes relacionados: \(error.localizedDescription)")
            relatedPerfumes = []
            #if DEBUG
            print("Error fetching related perfumes: \(error.localizedDescription)") // Debug print
            #endif
        }

        isLoadingRelated = false
    }

    private var recommendedPerfumesView: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("RECOMENDADOS PARA TI")
                .font(.headline)
                .foregroundColor(Color("textoPrincipal"))

            PerfumeHorizontalListView(
                allPerfumes: relatedPerfumes,
                onPerfumeTap: { perfume in
                    selectedPerfume = perfume
                },
                showAllPerfumesSheet: $isPresentingAllPerfumes
            )
            .frame(height: 200) // Ajustar la altura según sea necesario
            .padding(.bottom, 20) // Añadir espacio inferior
        }
    }

    private func testSummary(proxy: ScrollViewProxy) -> some View {
        VStack {
            if let questionsAndAnswers = profile.questionsAndAnswers, !questionsAndAnswers.isEmpty {
                AccordionView(isExpanded: $isAccordionExpanded) {
                    summaryContent(questionsAndAnswers: Array(questionsAndAnswers))
                        .id("AccordionSection")
                }
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.bottom, 16)
                .onChange(of: isAccordionExpanded) {
                    if isAccordionExpanded {
                        DispatchQueue.main.async {
                            proxy.scrollTo("AccordionSection", anchor: .top)
                        }
                    }
                }
            } else {
                Text("No hay datos disponibles")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    private func summaryContent(questionsAndAnswers: [QuestionAnswer]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(questionsAndAnswers, id: \.id) { qa in
                let texts = testViewModel.findQuestionAndAnswerTexts(
                    for: qa.questionId,
                    answerId: qa.answerId
                )

                if let questionText = texts.question, let answerText = texts.answer {
                    VStack(alignment: .leading) {
                        Text("Pregunta: \(questionText)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#2D3748"))
                        Text("Respuesta: \(answerText)")
                            .font(.body)
                            .foregroundColor(Color(hex: "#4A5568"))
                    }
                } else {
                    Text("Datos no disponibles")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
