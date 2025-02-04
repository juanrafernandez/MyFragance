import SwiftUI

struct TestResultView: View {
    let profile: OlfactiveProfile
    let isFromTest: Bool

    @Binding var isTestActive: Bool
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isSavePopupVisible = false
    @State private var isAccordionExpanded = false
    @State private var saveName: String = ""
    @State private var showExitAlert = false
    @State private var selectedPerfume: Perfume?

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        profileHeader
                        recommendedPerfumes
                        testSummary(proxy: proxy)
                    }
                }

                if isFromTest {
                    saveProfileButton
                }
            }
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                navigationToolbar
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(
                    perfume: perfume,
                    relatedPerfumes: perfumeViewModel.getRelatedPerfumes(for: profile)
                )
            }
            .sheet(isPresented: $isSavePopupVisible) {
                SaveProfileView(
                    profile: profile,
                    saveName: $saveName,
                    isSavePopupVisible: $isSavePopupVisible,
                    isTestActive: $isTestActive
                )
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

    private var recommendedPerfumes: some View {
        TestRecommendedPerfumesView(profile: profile, selectedPerfume: $selectedPerfume)
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
                    for: qa.questionId.uuidString,
                    answerId: qa.answerId.uuidString
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

    private var saveProfileButton: some View {
        Button(action: { isSavePopupVisible = true }) {
            Text("Guardar Perfil")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#F6AD55"))
                .foregroundColor(.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if isFromTest {
                Button(action: { showExitAlert = true }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
                .alert(isPresented: $showExitAlert) {
                    Alert(
                        title: Text("¿Salir sin guardar?"),
                        message: Text("Los datos no se guardarán si sales."),
                        primaryButton: .destructive(Text("Salir")) {
                            isTestActive = false
                        },
                        secondaryButton: .cancel()
                    )
                }
            } else {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
