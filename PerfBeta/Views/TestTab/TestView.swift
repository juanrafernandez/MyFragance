import SwiftUI

struct TestView: View {
    @StateObject private var viewModel = TestViewModel()
    @Binding var isTestActive: Bool
    @State private var navigateToSummary = false
    @State private var profile: OlfactiveProfile?

    var body: some View {
        NavigationStack {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage.value)
                } else if let currentQuestion = viewModel.currentQuestion {
                    // ✅ Vista de pregunta usando el ViewModel original
                    questionFlowView(currentQuestion)
                        .onAppear {
                            #if DEBUG
                            print("🎯 [TestView] Mostrando pregunta \(viewModel.currentQuestionIndex + 1)/\(viewModel.questions.count)")
                            print("   Pregunta: \(currentQuestion.text.prefix(50))...")
                            print("   Opciones: \(currentQuestion.options.count)")
                            #endif
                        }
                } else {
                    noQuestionsView
                }
            }
            .navigationDestination(isPresented: $navigateToSummary) {
                if let profile = profile {
                    TestResultNavigationView(profile: profile, isTestActive: $isTestActive)
                } else {
                    Text("Error: No se pudo generar el perfil.")
                }
            }
            .onChange(of: viewModel.olfactiveProfile) {
                profile = viewModel.olfactiveProfile
                navigateToSummary = true
            }
            .onAppear {
                #if DEBUG
                print("🎬 [TestView] Vista apareció")
                print("   Current index: \(viewModel.currentQuestionIndex)")
                print("   Questions loaded: \(viewModel.questions.count)")
                if let first = viewModel.currentQuestion {
                    print("   Primera pregunta key: \(first.key)")
                    print("   Primera pregunta texto: \(first.text.prefix(50))...")
                }
                #endif

                Task {
                    await viewModel.loadInitialData()
                }
            }
        }
    }

    // MARK: - Question Flow View

    private func questionFlowView(_ question: Question) -> some View {
        VStack(spacing: 0) {
            // Barra de progreso
            if !viewModel.questions.isEmpty {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("champan")))
                    .padding(.horizontal, 25)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(Color.white.opacity(0.05))
            }

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Categoría
                    Text(question.category.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("textoSecundario"))

                    // Pregunta
                    Text(question.text)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color("textoPrincipal"))
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtítulo
                    if let helperText = question.helperText {
                        Text(helperText)
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color("textoSecundario"))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Opciones
                    ForEach(question.options, id: \.id) { option in
                        StandardOptionButton(
                            option: option,
                            isSelected: viewModel.answers[question.key]?.id == option.id,
                            showDescription: true
                        ) {
                            // Guardar respuesta
                            viewModel.selectOption(option)

                            // Auto-avanzar con delay de 0.3 segundos
                            Task {
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                await viewModel.nextQuestion()
                            }
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("TEST DE PERFUMES")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Botón de retroceso a la izquierda
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.canGoBack {
                    Button(action: {
                        viewModel.previousQuestion()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color("textoPrincipal"))
                    }
                }
            }

            // Botón de cerrar a la derecha
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isTestActive = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color("textoPrincipal"))
                }
            }
        }
    }

    // MARK: - Helper Views

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
                .progressViewStyle(CircularProgressViewStyle(tint: Color("champan")))
                .scaleEffect(1.5)
            Text("Cargando preguntas...")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color("textoSecundario"))
        }
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
}
