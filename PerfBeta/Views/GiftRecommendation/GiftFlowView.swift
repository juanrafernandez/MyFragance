import SwiftUI

struct GiftFlowView: View {
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Environment(\.dismiss) var dismiss

    let onDismiss: (() -> Void)?  // ✅ Closure para cerrar después de guardar

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header con progreso
                headerView

                // Contenido principal
                if giftRecommendationViewModel.isShowingResults {
                    // Mostrar resultados
                    GiftResultsView(onDismiss: onDismiss, isStandalone: false)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if let currentQuestion = giftRecommendationViewModel.currentQuestion {
                    // Mostrar pregunta actual
                    questionFlowView(currentQuestion)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    // Estado de carga
                    loadingView
                }
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.3), value: giftRecommendationViewModel.currentQuestionIndex)
        .animation(.easeInOut(duration: 0.3), value: giftRecommendationViewModel.isShowingResults)
        .onAppear {
            // Siempre resetear el flujo cuando se abre la vista
            Task {
                await giftRecommendationViewModel.startNewFlow()
            }
        }
    }

    // MARK: - Question Flow View

    private func questionFlowView(_ question: Question) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    // Título de la pregunta
                    Text(question.text)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color("textoPrincipal"))
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtítulo (si existe)
                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color("textoSecundario"))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Opciones según el tipo de UI
                    optionsView(for: question)
                }

                // Solo mostrar botones si es selección múltiple o entrada de texto
                if shouldShowNavigationButtons(for: question) {
                    navigationButtons
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 20)
        }
    }

    @ViewBuilder
    private func optionsView(for question: Question) -> some View {
        let currentResponse = giftRecommendationViewModel.responses.getResponse(for: question.id)
        let selectedOptions = currentResponse?.selectedOptions ?? []

        if question.multiSelect == true {
            // Selección múltiple
            multipleSelectionView(
                question: question,
                selectedOptions: selectedOptions
            )
        } else {
            // Selección simple
            singleSelectionView(
                question: question,
                selectedOption: selectedOptions.first
            )
        }
    }

    private func singleSelectionView(question: Question, selectedOption: String?) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                StandardOptionButton(
                    giftOption: option,
                    isSelected: selectedOption == option.value,
                    showDescription: true  // Siempre mostrar descripciones
                ) {
                    giftRecommendationViewModel.answerQuestion(with: [option.id])

                    // Pequeño delay para que se vea la selección antes de avanzar
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await giftRecommendationViewModel.nextQuestion()
                    }
                }
            }
        }
    }

    private func multipleSelectionView(question: Question, selectedOptions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Indicador de selección mínima/máxima
            if let min = question.minSelections, let max = question.maxSelections {
                Text("Selecciona entre \(min) y \(max) opciones")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            } else if let min = question.minSelections {
                Text("Selecciona al menos \(min) opción\(min > 1 ? "es" : "")")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            }

            ForEach(question.options) { option in
                StandardOptionButton(
                    giftOption: option,
                    isSelected: selectedOptions.contains(option.value),
                    showDescription: true  // Siempre mostrar descripciones
                ) {
                    toggleMultipleSelection(
                        optionId: option.id,
                        currentSelection: selectedOptions,
                        question: question,
                        maxSelection: question.maxSelections
                    )
                }
            }
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await giftRecommendationViewModel.nextQuestion()
                }
            }) {
                HStack {
                    Text(giftRecommendationViewModel.isLastQuestion ? "Ver Resultados" : "Continuar")
                    if !giftRecommendationViewModel.isLastQuestion {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    giftRecommendationViewModel.canContinue
                        ? Color("champan")
                        : Color.gray.opacity(0.3)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!giftRecommendationViewModel.canContinue)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }

    private func shouldShowNavigationButtons(for question: Question) -> Bool {
        return question.multiSelect == true || question.dataSource != nil
    }

    private func toggleMultipleSelection(
        optionId: String,
        currentSelection: [String],
        question: Question,
        maxSelection: Int?
    ) {
        var selectedIds = currentSelection.compactMap { value in
            question.options.first(where: { $0.value == value })?.id
        }

        if let index = selectedIds.firstIndex(of: optionId) {
            selectedIds.remove(at: index)
        } else {
            if let max = maxSelection, selectedIds.count >= max {
                selectedIds.removeFirst()
            }
            selectedIds.append(optionId)
        }

        giftRecommendationViewModel.answerQuestion(with: selectedIds)

        // Si alcanzó el máximo, avanzar automáticamente
        if let max = maxSelection, selectedIds.count >= max {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await giftRecommendationViewModel.nextQuestion()
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    // Si estamos mostrando resultados, volver a la última pregunta
                    if giftRecommendationViewModel.isShowingResults {
                        giftRecommendationViewModel.isShowingResults = false
                    } else if giftRecommendationViewModel.canGoBack {
                        giftRecommendationViewModel.previousQuestion()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("textoPrincipal"))
                }

                Spacer()

                Text("BUSCAR REGALO")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("textoPrincipal"))
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 16)

            // Barra de progreso
            if !giftRecommendationViewModel.currentQuestions.isEmpty {
                ProgressView(value: giftRecommendationViewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("champan")))
                    .padding(.horizontal, 25)
                    .padding(.top, 8)
            }
        }
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("champan")))
                .scaleEffect(1.5)

            Text("Cargando preguntas...")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color("textoSecundario"))
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationView {
        GiftFlowView()
            .environmentObject(GiftRecommendationViewModel(
                authService: DependencyContainer.shared.authService
            ))
    }
}
