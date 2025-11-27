import SwiftUI

/// Vista unificada para mostrar cualquier flujo de preguntas
/// Usado tanto para test personal como para flujo de regalo
struct UnifiedQuestionFlowView: View {
    @StateObject private var viewModel = UnifiedQuestionFlowViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel

    // MARK: - Configuration

    let title: String
    let questions: [UnifiedQuestion]
    let showBackButton: Bool
    let onComplete: ([String: UnifiedResponse]) -> Void
    let onDismiss: (() -> Void)?
    @Binding var navigationProfile: OlfactiveProfile?
    let showResults: Bool
    let isGiftFlow: Bool  // Nuevo: indica si es flujo de regalo

    // MARK: - Save State
    @State private var isSavePopupVisible = false
    @State private var saveName: String = ""
    @State private var showCloseConfirmation = false
    @State private var hasBeenSaved = false

    init(
        title: String,
        questions: [UnifiedQuestion],
        showBackButton: Bool = true,
        navigationProfile: Binding<OlfactiveProfile?> = .constant(nil),
        showResults: Bool = false,
        isGiftFlow: Bool = false,  // Nuevo parámetro
        onComplete: @escaping ([String: UnifiedResponse]) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.questions = questions
        self.showBackButton = showBackButton
        self._navigationProfile = navigationProfile
        self.showResults = showResults
        self.isGiftFlow = isGiftFlow
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    headerView
                    contentView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showBackButton && viewModel.canGoBack {
                        Button(action: {
                            viewModel.previousQuestion()
                        }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss?()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .navigationDestination(item: $navigationProfile) { profile in
                if showResults {
                    UnifiedResultsView(
                        profile: profile,
                        isTestActive: .constant(true),
                        onSave: {
                            // Guardar perfil
                            Task {
                                // TODO: Implementar guardado del perfil
                                navigationProfile = nil
                                onDismiss?()
                            }
                        },
                        onRestartTest: {
                            navigationProfile = nil
                            onDismiss?()
                        }
                    )
                    .environmentObject(perfumeViewModel)
                    .environmentObject(brandViewModel)
                    .environmentObject(familyViewModel)
                    .navigationBarHidden(false)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                if hasBeenSaved {
                                    navigationProfile = nil
                                    onDismiss?()
                                } else {
                                    showCloseConfirmation = true
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(AppColor.textPrimary)
                            }
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Guardar") {
                                isSavePopupVisible = true
                            }
                            .foregroundColor(AppColor.brandAccent)
                        }
                    }
                    .alert("¿Salir sin guardar?", isPresented: $showCloseConfirmation) {
                        Button("Cancelar", role: .cancel) { }
                        Button("Salir sin guardar", role: .destructive) {
                            navigationProfile = nil
                            onDismiss?()
                        }
                    } message: {
                        Text("Si sales ahora, perderás los resultados de tu test olfativo. ¿Estás seguro?")
                    }
                    .sheet(isPresented: $isSavePopupVisible) {
                        if isGiftFlow {
                            // Flujo de regalo: usar SaveGiftProfileSheet
                            SaveGiftProfileSheet(
                                saveName: $saveName,
                                isSavePopupVisible: $isSavePopupVisible,
                                onSaved: {
                                    hasBeenSaved = true
                                    // Cerrar todo el flujo después de guardar
                                    navigationProfile = nil
                                    onDismiss?()
                                }
                            )
                            .environmentObject(giftRecommendationViewModel)
                        } else if let prof = navigationProfile {
                            // Flujo de perfil personal: usar SaveProfileView
                            SaveProfileView(
                                profile: prof,
                                saveName: $saveName,
                                isSavePopupVisible: $isSavePopupVisible,
                                isTestActive: .constant(true),
                                onSaved: {
                                    hasBeenSaved = true
                                    // Cerrar todo el flujo después de guardar
                                    navigationProfile = nil
                                    onDismiss?()
                                }
                            )
                            .environmentObject(olfactiveProfileViewModel)
                            .environmentObject(familyViewModel)
                        }
                    }
                }
            }
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
    }

    // MARK: - Header (Progress Bar Only)

    private var headerView: some View {
        VStack(spacing: 0) {
            // Barra de progreso
            if !questions.isEmpty {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColor.brandAccent))
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
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
                // Pregunta principal
                Text(question.text)
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(AppColor.textPrimary)
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
                        .foregroundColor(AppColor.textSecondary)
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
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.screenVertical)
            .padding(.bottom, AppSpacing.sectionSpacing)
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
        AutocompleteWrapper(viewModel: viewModel, question: question) { selectedKeys, searchText, didSkip, q in
            NotesAutocompleteView(
                selectedNoteKeys: selectedKeys,
                searchText: searchText,
                didSkip: didSkip,
                placeholder: q.textInputPlaceholder ?? "Busca: vainilla, jazmín, sándalo...",
                maxSelection: q.maxSelection ?? 3,
                showSkipOption: q.skipOption != nil,
                skipOptionLabel: q.skipOption?.label ?? "Omitir"
            )
            .environmentObject(notesViewModel)
        }
    }

    // MARK: - Brands Autocomplete

    private func brandsAutocompleteView(question: UnifiedQuestion) -> some View {
        AutocompleteWrapper(viewModel: viewModel, question: question) { selectedKeys, searchText, _, q in
            BrandAutocompleteView(
                selectedBrandKeys: selectedKeys,
                searchText: searchText,
                placeholder: q.textInputPlaceholder ?? "Buscar marcas...",
                maxSelection: q.maxSelection ?? 3
            )
            .environmentObject(brandViewModel)
        }
    }

    // MARK: - Perfumes Autocomplete

    private func perfumesAutocompleteView(question: UnifiedQuestion) -> some View {
        AutocompleteWrapper(viewModel: viewModel, question: question) { selectedKeys, searchText, didSkip, q in
            PerfumesAutocompleteView(
                selectedPerfumeKeys: selectedKeys,
                searchText: searchText,
                didSkip: didSkip,
                placeholder: q.textInputPlaceholder ?? "Busca perfumes de referencia...",
                maxSelection: q.maxSelection ?? 3,
                showSkipOption: q.skipOption != nil,
                skipOptionLabel: q.skipOption?.label ?? "Omitir"
            )
            .environmentObject(perfumeViewModel)
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
                    .foregroundColor(AppColor.textSecondary)
            } else if let min = question.minSelection {
                Text("Selecciona al menos \(min) opción\(min > 1 ? "es" : "")")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
            } else if let max = question.maxSelection {
                Text("Selecciona hasta \(max) opción\(max > 1 ? "es" : "")")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
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
                        ? AppColor.brandAccent
                        : Color.gray.opacity(0.3)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canContinue)
        }
        .padding(.top, AppSpacing.screenVertical)
    }

    // MARK: - Helper Views

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColor.brandAccent))
                .scaleEffect(1.5)

            Text("Cargando preguntas...")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppColor.textSecondary)
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
