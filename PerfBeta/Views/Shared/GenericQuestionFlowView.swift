import SwiftUI

// MARK: - Protocolos para Abstracción

/// Extensiones para conformar los modelos existentes a los protocolos
extension Option: QuestionOptionProtocol {
    // Ya conforma - tiene id, label, value, description
}

extension Question: QuestionProtocol {
    var subtitle: String? { helperText }
    var allowsMultipleSelection: Bool { multiSelect ?? false }
    var allowsTextInput: Bool { dataSource != nil }
    var textInputPlaceholder: String? { placeholder }
    var minSelection: Int? { minSelections }
    var maxSelection: Int? { maxSelections }
    var showDescriptions: Bool { true }
}

// MARK: - Protocolos para Abstracción

/// Protocolo que define una opción de respuesta genérica
protocol QuestionOptionProtocol: Identifiable {
    var id: String { get }
    var label: String { get }
    var value: String { get }
    var description: String? { get }
}

/// Protocolo que define una pregunta genérica
protocol QuestionProtocol: Identifiable {
    associatedtype OptionType: QuestionOptionProtocol

    var id: String { get }
    var text: String { get }
    var subtitle: String? { get }
    var category: String { get }
    var options: [OptionType] { get }
    var allowsMultipleSelection: Bool { get }
    var allowsTextInput: Bool { get }
    var textInputPlaceholder: String? { get }
    var minSelection: Int? { get }
    var maxSelection: Int? { get }
    var showDescriptions: Bool { get }
}

/// Protocolo que define el ViewModel para el flujo de preguntas
protocol QuestionFlowViewModelProtocol: ObservableObject {
    associatedtype QuestionType: QuestionProtocol

    var questions: [QuestionType] { get }
    var currentQuestionIndex: Int { get }
    var isLoading: Bool { get }
    var errorMessage: IdentifiableString? { get }
    var progress: Double { get }

    var currentQuestion: QuestionType? { get }
    var canGoBack: Bool { get }
    var canContinue: Bool { get }
    var isLastQuestion: Bool { get }

    func selectOption(_ optionId: String)
    func selectMultipleOptions(_ optionIds: [String])
    func inputText(_ text: String)
    func nextQuestion() async
    func previousQuestion()
    func isOptionSelected(_ optionId: String) -> Bool
    func getSelectedOptions() -> [String]
}

// MARK: - Vista Genérica de Preguntas

struct GenericQuestionFlowView<ViewModel: QuestionFlowViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss

    let title: String
    let onComplete: ((Any) -> Void)?  // Callback cuando se completa el flujo
    let showBackButton: Bool

    init(
        viewModel: ViewModel,
        title: String = "Cuestionario",
        showBackButton: Bool = true,
        onComplete: ((Any) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.title = title
        self.showBackButton = showBackButton
        self.onComplete = onComplete
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
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                if showBackButton && viewModel.canGoBack {
                    Button(action: {
                        viewModel.previousQuestion()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color("textoPrincipal"))
                    }
                } else {
                    Spacer()
                        .frame(width: 44)
                }

                Spacer()

                Text(title.uppercased())
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
            if !viewModel.questions.isEmpty {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("champan")))
                    .padding(.horizontal, 25)
                    .padding(.top, 8)

                Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 25)
            }
        }
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Content View

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

    private func questionView(_ question: ViewModel.QuestionType) -> some View {
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

                // Subtítulo (si existe)
                if let subtitle = question.subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Opciones
                if question.allowsTextInput {
                    textInputView(question: question)
                } else if question.allowsMultipleSelection {
                    multipleSelectionView(question: question)
                } else {
                    singleSelectionView(question: question)
                }

                // Botones de navegación (solo para selección múltiple o texto)
                if shouldShowNavigationButtons(for: question) {
                    navigationButtons
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Text Input View

    private func textInputView(question: ViewModel.QuestionType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(
                question.textInputPlaceholder ?? "Escribe aquí...",
                text: Binding(
                    get: { "" }, // TODO: Obtener del ViewModel
                    set: { newValue in
                        viewModel.inputText(newValue)
                    }
                )
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 8)
        }
    }

    // MARK: - Single Selection View

    private func singleSelectionView(question: ViewModel.QuestionType) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                optionButton(
                    option: option,
                    isSelected: viewModel.isOptionSelected(option.id),
                    showDescription: question.showDescriptions
                ) {
                    viewModel.selectOption(option.id)

                    // Auto-avanzar después de 0.3 segundos
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await viewModel.nextQuestion()
                    }
                }
            }
        }
    }

    // MARK: - Multiple Selection View

    private func multipleSelectionView(question: ViewModel.QuestionType) -> some View {
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
                optionButton(
                    option: option,
                    isSelected: viewModel.isOptionSelected(option.id),
                    showDescription: question.showDescriptions
                ) {
                    toggleMultipleSelection(option: option, question: question)
                }
            }
        }
    }

    // MARK: - Option Button (SIN IMAGEN)

    private func optionButton(
        option: ViewModel.QuestionType.OptionType,
        isSelected: Bool,
        showDescription: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.label)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .white : Color("textoPrincipal"))

                        if showDescription, let description = option.description {
                            Text(description)
                                .font(.system(size: 13, weight: .light))
                                .foregroundColor(isSelected ? .white.opacity(0.9) : Color("textoSecundario"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("champan") : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color("champan") : Color("champan").opacity(0.3),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.nextQuestion()
                }
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

    private func shouldShowNavigationButtons(for question: ViewModel.QuestionType) -> Bool {
        return question.allowsMultipleSelection || question.allowsTextInput
    }

    private func toggleMultipleSelection(
        option: ViewModel.QuestionType.OptionType,
        question: ViewModel.QuestionType
    ) {
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
                await viewModel.nextQuestion()
            }
        }
    }
}
