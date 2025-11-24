import SwiftUI

/// Vista unificada para mostrar cualquier flujo de preguntas
/// Usado tanto para test personal como para flujo de regalo
struct UnifiedQuestionFlowView: View {
    @StateObject private var viewModel = UnifiedQuestionFlowViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    // MARK: - Configuration

    let title: String
    let questions: [UnifiedQuestion]
    let showBackButton: Bool
    let onComplete: ([String: UnifiedResponse]) -> Void
    let onDismiss: (() -> Void)?

    init(
        title: String,
        questions: [UnifiedQuestion],
        showBackButton: Bool = true,
        onComplete: @escaping ([String: UnifiedResponse]) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.questions = questions
        self.showBackButton = showBackButton
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView
                contentView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            #if DEBUG
            print("🎯 [UnifiedQuestionFlow] Vista apareció - cargando \(questions.count) preguntas")
            #endif
            viewModel.loadQuestions(questions)
        }
        .onChange(of: viewModel.currentQuestionIndex) { oldValue, newValue in
            #if DEBUG
            print("📍 [UnifiedQuestionFlow] Índice cambió: \(oldValue) → \(newValue)")
            #endif
        }
        .onChange(of: viewModel.isCompleted) { oldValue, newValue in
            if newValue {
                let responses = viewModel.getAllResponses()
                onComplete(responses)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                // Botón de retroceso (estilo sistema)
                if showBackButton && viewModel.canGoBack {
                    Button(action: {
                        viewModel.previousQuestion()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                } else {
                    Spacer()
                        .frame(width: 44)
                }

                Spacer()

                Text(title.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("textoPrincipal"))

                Spacer()

                // Botón de cerrar (estilo sistema)
                Button(action: {
                    onDismiss?()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 16)

            // Barra de progreso
            if !questions.isEmpty {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("champan")))
                    .padding(.horizontal, 25)
                    .padding(.top, 8)
            }
        }
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage.value)
        } else if let question = viewModel.currentQuestion {
            questionView(question)
        } else {
            noQuestionsView
        }
    }

    // MARK: - Question View

    private func questionView(_ question: UnifiedQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Categoría
                Text(question.category.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("textoSecundario"))

                // Pregunta principal
                Text(question.text)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color("textoPrincipal"))
                    .fixedSize(horizontal: false, vertical: true)
                    .onAppear {
                        #if DEBUG
                        print("❓ [UnifiedQuestionFlow] Mostrando pregunta: \(question.text.prefix(50))...")
                        print("   Opciones: \(question.options.count)")
                        print("   Tipo: \(question.allowsMultipleSelection ? "Múltiple" : question.requiresTextInput ? "Texto" : "Simple")")
                        #endif
                    }

                // Subtítulo (si existe)
                if let subtitle = question.subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Opciones según el tipo
                if question.isAutocompleteNotes {
                    notesAutocompleteView(question: question)
                } else if question.isAutocompleteBrands {
                    brandsAutocompleteView(question: question)
                } else if question.isAutocompletePerfumes {
                    perfumesAutocompleteView(question: question)
                } else if question.requiresTextInput {
                    textInputView(question: question)
                } else if question.allowsMultipleSelection {
                    multipleSelectionView(question: question)
                } else {
                    singleSelectionView(question: question)
                }

                // Botones de navegación (solo para múltiple o texto)
                if shouldShowNavigationButtons(for: question) {
                    navigationButtons
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Text Input

    private func textInputView(question: UnifiedQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(
                question.textInputPlaceholder ?? "Escribe aquí...",
                text: Binding(
                    get: { viewModel.getTextInput() },
                    set: { newValue in
                        viewModel.inputText(newValue)
                    }
                )
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 8)
        }
    }

    // MARK: - Notes Autocomplete

    private func notesAutocompleteView(question: UnifiedQuestion) -> some View {
        NotesAutocompleteWrapper(
            viewModel: viewModel,
            notesViewModel: notesViewModel,
            question: question
        )
    }

    // MARK: - Brands Autocomplete

    private func brandsAutocompleteView(question: UnifiedQuestion) -> some View {
        BrandsAutocompleteWrapper(
            viewModel: viewModel,
            brandViewModel: brandViewModel,
            question: question
        )
    }

    // MARK: - Perfumes Autocomplete

    private func perfumesAutocompleteView(question: UnifiedQuestion) -> some View {
        PerfumesAutocompleteWrapper(
            viewModel: viewModel,
            perfumeViewModel: perfumeViewModel,
            question: question
        )
    }
}

// MARK: - Notes Autocomplete Wrapper

private struct NotesAutocompleteWrapper: View {
    @ObservedObject var viewModel: UnifiedQuestionFlowViewModel
    @ObservedObject var notesViewModel: NotesViewModel
    let question: UnifiedQuestion

    @State private var selectedNoteKeys: [String] = []
    @State private var searchText: String = ""
    @State private var didSkip: Bool = false

    var body: some View {
        NotesAutocompleteView(
            selectedNoteKeys: $selectedNoteKeys,
            searchText: $searchText,
            didSkip: $didSkip,
            placeholder: question.textInputPlaceholder ?? "Busca: vainilla, jazmín, sándalo...",
            maxSelection: question.maxSelection ?? 3,
            showSkipOption: question.skipOption != nil,
            skipOptionLabel: question.skipOption?.label ?? "Omitir"
        )
        .environmentObject(notesViewModel)
        .onAppear {
            selectedNoteKeys = viewModel.getSelectedOptions()
            searchText = viewModel.getTextInput()
            didSkip = selectedNoteKeys.contains("skip")
        }
        .onChange(of: selectedNoteKeys) { _, newValue in
            viewModel.selectMultipleOptions(newValue)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.inputText(newValue)
        }
        .onChange(of: didSkip) { _, newValue in
            if newValue {
                viewModel.selectMultipleOptions(["skip"])
            }
        }
    }
}

// MARK: - Perfumes Autocomplete Wrapper

private struct PerfumesAutocompleteWrapper: View {
    @ObservedObject var viewModel: UnifiedQuestionFlowViewModel
    @ObservedObject var perfumeViewModel: PerfumeViewModel
    let question: UnifiedQuestion

    @State private var selectedPerfumeKeys: [String] = []
    @State private var searchText: String = ""
    @State private var didSkip: Bool = false

    var body: some View {
        PerfumesAutocompleteView(
            selectedPerfumeKeys: $selectedPerfumeKeys,
            searchText: $searchText,
            didSkip: $didSkip,
            placeholder: question.textInputPlaceholder ?? "Busca perfumes de referencia...",
            maxSelection: question.maxSelection ?? 3,
            showSkipOption: question.skipOption != nil,
            skipOptionLabel: question.skipOption?.label ?? "Omitir"
        )
        .environmentObject(perfumeViewModel)
        .onAppear {
            selectedPerfumeKeys = viewModel.getSelectedOptions()
            searchText = viewModel.getTextInput()
            didSkip = selectedPerfumeKeys.contains("skip")
        }
        .onChange(of: selectedPerfumeKeys) { _, newValue in
            viewModel.selectMultipleOptions(newValue)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.inputText(newValue)
        }
        .onChange(of: didSkip) { _, newValue in
            if newValue {
                viewModel.selectMultipleOptions(["skip"])
            }
        }
    }
}

// MARK: - Brands Autocomplete Wrapper

private struct BrandsAutocompleteWrapper: View {
    @ObservedObject var viewModel: UnifiedQuestionFlowViewModel
    @ObservedObject var brandViewModel: BrandViewModel
    let question: UnifiedQuestion

    @State private var selectedBrandKeys: [String] = []
    @State private var searchText: String = ""

    var body: some View {
        BrandAutocompleteView(
            selectedBrandKeys: $selectedBrandKeys,
            searchText: $searchText,
            placeholder: question.textInputPlaceholder ?? "Buscar marcas...",
            maxSelection: question.maxSelection ?? 3
        )
        .environmentObject(brandViewModel)
        .onAppear {
            selectedBrandKeys = viewModel.getSelectedOptions()
            searchText = viewModel.getTextInput()
        }
        .onChange(of: selectedBrandKeys) { _, newValue in
            viewModel.selectMultipleOptions(newValue)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.inputText(newValue)
        }
    }
}

// MARK: - Continue UnifiedQuestionFlowView

extension UnifiedQuestionFlowView {
    // MARK: - Single Selection

    private func singleSelectionView(question: UnifiedQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                StandardOptionButton(
                    label: option.label,
                    description: option.description,
                    isSelected: viewModel.isOptionSelected(option.id),
                    showDescription: question.showDescriptions
                ) {
                    viewModel.selectOption(option.id)

                    // Auto-avanzar después de 0.3 segundos
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        viewModel.nextQuestion()
                    }
                }
            }
        }
    }

    // MARK: - Multiple Selection

    private func multipleSelectionView(question: UnifiedQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Indicador de selección
            if let min = question.minSelection, let max = question.maxSelection {
                Text("Selecciona entre \(min) y \(max) opciones")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            } else if let min = question.minSelection {
                Text("Selecciona al menos \(min) opción\(min > 1 ? "es" : "")")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            } else if let max = question.maxSelection {
                Text("Selecciona hasta \(max) opción\(max > 1 ? "es" : "")")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            }

            ForEach(question.options) { option in
                StandardOptionButton(
                    label: option.label,
                    description: option.description,
                    isSelected: viewModel.isOptionSelected(option.id),
                    showDescription: question.showDescriptions
                ) {
                    toggleMultipleSelection(option: option, question: question)
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.nextQuestion()
            }) {
                HStack {
                    Text(viewModel.isLastQuestion ? "Ver Resultados" : "Continuar")
                    if !viewModel.isLastQuestion {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    viewModel.canContinue
                        ? Color("champan")
                        : Color.gray.opacity(0.3)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canContinue)
        }
        .padding(.top, 20)
    }

    // MARK: - Helper Views

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

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.red)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }

    private var noQuestionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)

            Text("No hay preguntas disponibles.")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func shouldShowNavigationButtons(for question: UnifiedQuestion) -> Bool {
        return question.allowsMultipleSelection || question.requiresTextInput || question.isAutocompleteNotes || question.isAutocompleteBrands || question.isAutocompletePerfumes
    }

    private func toggleMultipleSelection(option: UnifiedOption, question: UnifiedQuestion) {
        var selectedOptions = viewModel.getSelectedOptions()

        if let index = selectedOptions.firstIndex(of: option.id) {
            // Deseleccionar
            selectedOptions.remove(at: index)
        } else {
            // Seleccionar (verificar máximo)
            if let max = question.maxSelection, selectedOptions.count >= max {
                selectedOptions.removeFirst()
            }
            selectedOptions.append(option.id)
        }

        viewModel.selectMultipleOptions(selectedOptions)

        // Auto-avanzar si alcanzó el máximo
        if let max = question.maxSelection, selectedOptions.count >= max {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                viewModel.nextQuestion()
            }
        }
    }
}
