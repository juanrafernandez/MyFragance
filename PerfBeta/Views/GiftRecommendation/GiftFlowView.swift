import SwiftUI

struct GiftFlowView: View {
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Environment(\.dismiss) var dismiss

    let onDismiss: (() -> Void)?  // ✅ Closure para cerrar después de guardar

    @State private var isShowingResults = false
    @State private var selectedPerfumeKey: String?  // Para autocompletar perfumes
    @State private var selectedBrandKeys: [String] = []  // Para autocompletar marcas
    @State private var searchText: String = ""  // Para autocompletar

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
                    // Mostrar resultados (dentro del flujo, sin UI standalone)
                    GiftResultsView(onDismiss: onDismiss, isStandalone: false)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if let currentQuestion = giftRecommendationViewModel.currentQuestion {
                    // Mostrar pregunta actual
                    ScrollView {
                        VStack(spacing: 20) {
                            questionView(currentQuestion)

                            // ✅ Solo mostrar botones si es selección múltiple o entrada de texto
                            if shouldShowNavigationButtons(for: currentQuestion) {
                                navigationButtons
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.top, 20)
                    }
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

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    // ✅ Si estamos mostrando resultados, volver a la última pregunta
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

    // MARK: - Question View

    private func questionView(_ question: GiftQuestion) -> some View {
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
        .padding(.vertical, 20)
    }

    // MARK: - Options View

    @ViewBuilder
    private func optionsView(for question: GiftQuestion) -> some View {
        let currentResponse = giftRecommendationViewModel.responses.getResponse(for: question.id)
        let selectedOptions = currentResponse?.selectedOptions ?? []

        if question.uiConfig.isTextInput {
            // Input de texto
            textInputView(question: question, currentText: currentResponse?.textInput ?? "")
        } else if question.uiConfig.isMultipleSelection {
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

    // MARK: - Text Input View

    private func textInputView(question: GiftQuestion, currentText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Si es búsqueda de perfume, usar autocompletar
            if question.uiConfig.textInputType == "search" {
                let selectedGender = giftRecommendationViewModel.responses.getValue(for: "perfume_type")  // ✅ Categoria correcta

                PerfumeAutocompleteView(
                    selectedPerfumeKey: $selectedPerfumeKey,
                    searchText: $searchText,
                    placeholder: question.uiConfig.placeholder ?? "Buscar perfume...",
                    filterGender: selectedGender
                )
                .environmentObject(perfumeViewModel)
                .onChange(of: selectedPerfumeKey) { oldValue, newValue in
                    if let key = newValue {
                        // Guardar el key del perfume seleccionado
                        giftRecommendationViewModel.answerQuestion(
                            with: [],
                            textInput: key
                        )
                    } else {
                        // Si se deselecciona, limpiar respuesta
                        giftRecommendationViewModel.answerQuestion(
                            with: [],
                            textInput: ""
                        )
                    }
                }
                .onAppear {
                    // Restaurar valor si existe
                    if !currentText.isEmpty {
                        searchText = currentText
                        selectedPerfumeKey = currentText
                    }
                }
            } else if question.uiConfig.textInputType == "brand_search" {
                // ✅ Búsqueda de marcas con selección múltiple
                let maxSelection = question.uiConfig.maxSelection ?? 5

                BrandAutocompleteView(
                    selectedBrandKeys: $selectedBrandKeys,
                    searchText: $searchText,
                    placeholder: question.uiConfig.placeholder ?? "Buscar marcas...",
                    maxSelection: maxSelection
                )
                .environmentObject(brandViewModel)
                .onChange(of: selectedBrandKeys) { oldValue, newValue in
                    // ✅ Guardar las marcas seleccionadas directamente en selectedOptions
                    // Los keys de las marcas se usan como valores
                    giftRecommendationViewModel.answerQuestion(
                        with: newValue,  // ✅ Los keys de las marcas
                        textInput: nil
                    )

                    #if DEBUG
                    print("📝 [GiftFlow] Brand selection changed: \(newValue.count) brands")
                    print("   Keys: \(newValue.joined(separator: ", "))")
                    #endif
                }
                .onAppear {
                    // ✅ Restaurar valores desde selectedOptions
                    let currentResponse = giftRecommendationViewModel.responses.getResponse(for: question.id)
                    if let selectedOptions = currentResponse?.selectedOptions, !selectedOptions.isEmpty {
                        selectedBrandKeys = selectedOptions
                        #if DEBUG
                        print("🔄 [GiftFlow] Restored \(selectedOptions.count) brands: \(selectedOptions.joined(separator: ", "))")
                        #endif
                    }
                }
            } else {
                // Input de texto normal
                TextField(
                    question.uiConfig.placeholder ?? "Escribe aquí...",
                    text: Binding(
                        get: { currentText },
                        set: { newValue in
                            giftRecommendationViewModel.answerQuestion(
                                with: [],
                                textInput: newValue
                            )
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Single Selection View

    private func singleSelectionView(question: GiftQuestion, selectedOption: String?) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options) { option in
                optionButton(
                    option: option,
                    isSelected: selectedOption == option.value,  // ✅ Comparar con VALUE
                    showDescription: question.uiConfig.showDescriptions == true
                ) {
                    // ✅ Responder y avanzar automáticamente
                    giftRecommendationViewModel.answerQuestion(with: [option.id])

                    // Pequeño delay para que se vea la selección antes de avanzar
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos
                        await giftRecommendationViewModel.nextQuestion()
                    }
                }
            }
        }
    }

    // MARK: - Multiple Selection View

    private func multipleSelectionView(question: GiftQuestion, selectedOptions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Indicador de selección mínima/máxima
            if let min = question.uiConfig.minSelection, let max = question.uiConfig.maxSelection {
                Text("Selecciona entre \(min) y \(max) opciones")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            } else if let min = question.uiConfig.minSelection {
                Text("Selecciona al menos \(min) opción\(min > 1 ? "es" : "")")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))
            }

            ForEach(question.options) { option in
                optionButton(
                    option: option,
                    isSelected: selectedOptions.contains(option.value),  // ✅ Comparar con VALUE
                    showDescription: question.uiConfig.showDescriptions == true
                ) {
                    toggleMultipleSelection(
                        optionId: option.id,
                        currentSelection: selectedOptions,
                        question: question,
                        maxSelection: question.uiConfig.maxSelection
                    )
                }
            }
        }
    }

    // MARK: - Option Button

    private func optionButton(
        option: GiftQuestionOption,
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
            // ✅ Solo un botón: Continuar o Ver Resultados
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

    // MARK: - Helper Methods

    /// Determina si se deben mostrar los botones de navegación
    /// Solo se muestran para selección múltiple o entrada de texto
    private func shouldShowNavigationButtons(for question: GiftQuestion) -> Bool {
        // Mostrar botones si es selección múltiple
        if question.uiConfig.isMultipleSelection {
            return true
        }

        // Mostrar botones si es entrada de texto
        if question.uiConfig.isTextInput {
            return true
        }

        // Para selección simple, NO mostrar botones (auto-avanza)
        return false
    }

    private func toggleMultipleSelection(
        optionId: String,
        currentSelection: [String],  // ✅ Ahora contiene VALUES
        question: GiftQuestion,
        maxSelection: Int?
    ) {
        // Trabajar con IDs para construir la nueva selección
        var selectedIds = currentSelection.compactMap { value in
            question.options.first(where: { $0.value == value })?.id
        }

        if let index = selectedIds.firstIndex(of: optionId) {
            // Deseleccionar
            selectedIds.remove(at: index)
        } else {
            // Seleccionar (verificar máximo)
            if let max = maxSelection, selectedIds.count >= max {
                // Si ya alcanzó el máximo, reemplazar el primero
                selectedIds.removeFirst()
            }
            selectedIds.append(optionId)
        }

        giftRecommendationViewModel.answerQuestion(with: selectedIds)

        // ✅ Si alcanzó el máximo, avanzar automáticamente
        if let max = maxSelection, selectedIds.count >= max {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos para que se vea la selección
                await giftRecommendationViewModel.nextQuestion()
            }
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
