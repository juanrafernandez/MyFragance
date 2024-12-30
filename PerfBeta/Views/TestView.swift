import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    @Binding var isTestActive: Bool
    @State private var navigateToSummary = false // Controla la navegación a SummaryView
    @State private var showScrollIndicator = false // Controla la visibilidad del indicador
    @State private var scrollIndex: Int = 0 // Índice actual para desplazamiento

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                if !viewModel.questions.isEmpty {
                    questionScrollView
                } else {
                    loadingView
                }
            }
            .navigationTitle("Test de Perfumes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeButton }
            .background(gradientBackground)
            .onAppear {
                evaluateScrollIndicatorOnAppear()
            }
            .navigationDestination(isPresented: $navigateToSummary) {
                resultView
            }
        }
    }

    // MARK: - Subviews

    private var progressBar: some View {
        ProgressView(value: viewModel.progress)
            .progressViewStyle(.linear)
            .tint(Color(hex: "#F6AD55"))
            .padding(.horizontal)
            .padding(.top, 10)
    }

    private var questionScrollView: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        questionCategory
                        questionText
                        optionButtons(proxy: proxy, geometry: geometry)
                    }
                    .padding()
                    .background(scrollIndicatorEvaluator(geometry: geometry))
                }
                .overlay(scrollIndicator(proxy: proxy))
            }
        }
    }

    private var questionCategory: some View {
        Group {
            if !viewModel.currentQuestion.category.isEmpty {
                Text(viewModel.currentQuestion.category.uppercased())
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .padding(.top)
            } else {
                EmptyView() // Retorna un EmptyView cuando no hay categoría
            }
        }
    }

    private var questionText: some View {
        Text(viewModel.currentQuestion.text)
            .font(.title)
            .multilineTextAlignment(.center)
            .padding()
    }

    private func optionButtons(proxy: ScrollViewProxy, geometry: GeometryProxy) -> some View {
        ForEach(viewModel.currentQuestion.options) { option in
            OptionButton(
                option: option,
                isSelected: viewModel.answers[viewModel.currentQuestion.id]?.value == option.value
            ) {
                handleOptionSelection(option)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .id(option.id)
        }
    }

    private func scrollIndicatorEvaluator(geometry: GeometryProxy) -> some View {
        GeometryReader { contentGeometry in
            Color.clear.onAppear {
                evaluateScrollIndicator(
                    contentHeight: contentGeometry.size.height,
                    visibleHeight: geometry.size.height
                )
            }
            .onChange(of: viewModel.currentQuestion.id) { _ in
                evaluateScrollIndicator(
                    contentHeight: contentGeometry.size.height,
                    visibleHeight: geometry.size.height
                )
            }
        }
    }

    private func scrollIndicator(proxy: ScrollViewProxy) -> some View {
        VStack {
            Spacer()
            if showScrollIndicator {
                Button(action: {
                    withAnimation {
                        scrollIndex += 1
                        if scrollIndex >= viewModel.currentQuestion.options.count {
                            scrollIndex = 0
                        }
                        proxy.scrollTo(viewModel.currentQuestion.options[scrollIndex].id, anchor: .top)
                    }
                }) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.bottom, 10)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Cargando preguntas...")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
    }

    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#F3E9E5"), .white]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var closeButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { isTestActive = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }

    private var resultView: some View {
        TestResultView(
            title: "¡Hemos encontrado tu perfil olfativo perfecto!",
            summary: viewModel.questions.map { question in
                (question.text, viewModel.answers[question.id]?.label ?? "Sin respuesta")
            },
            profileName: "Floral",
            profileDescription: "Fragancias suaves y delicadas con predominio de flores frescas.",
            profileGradient: [Color(hex: "#FFFAF0"), Color(hex: "#FFE4E1")],
            profileIcon: "icon_florales",
            recommendedPerfumes: MockPerfumes.perfumes.filter { $0.familia == "florales" },
            isFromTest: true,
            isTestActive: $isTestActive // Se añade el binding aquí
        )
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers

    private func evaluateScrollIndicator(contentHeight: CGFloat, visibleHeight: CGFloat) {
        showScrollIndicator = contentHeight > visibleHeight
    }

    private func evaluateScrollIndicatorOnAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            evaluateScrollIndicator(
                contentHeight: calculateInitialContentHeight(),
                visibleHeight: UIScreen.main.bounds.height
            )
        }
    }

    private func calculateInitialContentHeight() -> CGFloat {
        let questionHeight: CGFloat = 100
        let padding: CGFloat = 40
        return CGFloat(viewModel.currentQuestion.options.count) * questionHeight + padding
    }

    private func handleOptionSelection(_ option: Option) {
        let isLastQuestion = viewModel.selectOption(option)
        if isLastQuestion {
            DispatchQueue.main.async {
                navigateToSummary = true
            }
        }
    }
}

/// Subcomponente para los botones de opciones
struct OptionButton: View {
    let option: Option
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(option.imageAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color(.primaryButton) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}
