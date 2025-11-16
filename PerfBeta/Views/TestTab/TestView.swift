import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    @Binding var isTestActive: Bool
    @State private var navigateToSummary = false
    @State private var profile: OlfactiveProfile?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                contentView
                Spacer()
            }
            .navigationTitle("Test de Perfumes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeButton }
            .background(
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationDestination(isPresented: $navigateToSummary) {
                if let profile = profile {
                    TestResultNavigationView(profile: profile, isTestActive: $isTestActive)
                } else {
                    Text("Error: No se pudo generar el perfil.")
                }
            }
            .onChange(of: viewModel.olfactiveProfile) { // Keep onChange logic for test completion ONLY
                profile = viewModel.olfactiveProfile // Update local 'profile' state with test result
                navigateToSummary = true // Navigate to summary after test completion
            }
        }
    }

    // MARK: - Función para iniciar el test después de seleccionar el nivel (Sin cambios)
    private func startTest() {
        Task {
            await viewModel.loadInitialData()
        }
    }

    // MARK: - Subviews (Sin cambios)
    private var progressBar: some View {
        VStack(alignment: .leading) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(Color(hex: "#F6AD55"))
            Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var contentView: some View {
        if viewModel.isLoading {
            return AnyView(loadingView)
        } else if let errorMessage = viewModel.errorMessage {
            return AnyView(errorView(message: errorMessage.value))
        } else if !viewModel.questions.isEmpty {
            return AnyView(questionView(for: viewModel.currentQuestion ?? viewModel.questions.first!))
        } else {
            return AnyView(noQuestionsView)
        }
    }

    private func questionView(for question: Question) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(question.category.uppercased())
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                Text(question.text)
                    .font(.title2)
                    .multilineTextAlignment(.center)

                ForEach(question.options, id: \.id) { option in
                    OptionButton(
                        option: option,
                        isSelected: viewModel.answers[question.id]?.value == option.value
                    ) {
                        _ = viewModel.selectOption(option)
                    }
                }
            }
            .padding()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.red)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Button("Reintentar") {
                Task {
                    await viewModel.loadInitialData()
                }
            }
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Cargando preguntas...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var noQuestionsView: some View {
        VStack {
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

    private var closeButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { isTestActive = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
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
                // Imagen de la opción
                Image(option.image_asset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Contenido textual de la opción
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.label)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.leading) // Asegura alineación a la izquierda
                        .lineLimit(2) // Limita el número de líneas si es necesario
                    
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading) // Asegura alineación a la izquierda
                        .lineLimit(3) // Limita el número de líneas si es necesario
                }
                .padding(.vertical, 8) // Añade padding vertical para mejorar la apariencia
            }
            .padding(.horizontal, 16) // Añade padding horizontal
            .frame(maxWidth: .infinity, alignment: .leading) // Alinea todo el contenido a la izquierda
            .background(
                ZStack {
                    if isSelected {
                        Color.blue
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    }
                }
            )
        }
        .padding(.horizontal) // Añade padding horizontal al botón completo
    }
}
