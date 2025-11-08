import SwiftUI
import Kingfisher

/// Vista de ficha completa de perfume para el flujo de añadir perfume
/// Combina el diseño de PerfumeDetailView con botones personalizados:
/// - Botón "Guardar" en toolbar (arriba derecha)
/// - Botón "Mi Opinión" al final (para evaluación completa)
struct AddPerfumeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    let perfume: Perfume
    @Binding var isAddingPerfume: Bool
    @Binding var showingEvaluationOnboarding: Bool

    @State private var fullPerfume: Perfume?
    @State private var isLoadingPerfume = false
    @State private var isSaving = false
    @State private var showSaveConfirmation = false

    var displayPerfume: Perfume {
        fullPerfume ?? perfume
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            if isLoadingPerfume {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Cargando información del perfume...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection.padding(.horizontal, 20)
                        descriptionSection
                        olfactoryPyramidSection
                        recommendationsSection

                        // Botón "Mi Opinión" al final
                        opinionButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Ficha")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
        }
        .alert("Guardar sin opinión", isPresented: $showSaveConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Guardar") {
                Task {
                    await saveBasicPerfume()
                }
            }
        } message: {
            Text("¿Quieres guardar este perfume en tus probados sin dejar tu opinión? Podrás añadir tu opinión más tarde.")
        }
        .task {
            await loadFullPerfume()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center) {
            KFImage(displayPerfume.imageURL.flatMap { URL(string: $0) })
                .placeholder {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.bottom, 10)

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayPerfume.name)
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(Color("textoPrincipal"))
                        .lineLimit(2)

                    Text(brandViewModel.getBrand(byKey: displayPerfume.brand)?.name ?? displayPerfume.brand)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                }
                Spacer()

                if let brand = brandViewModel.getBrand(byKey: displayPerfume.brand),
                   let brandLogoURL = brand.imagenURL,
                   let url = URL(string: brandLogoURL) {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .cornerRadius(22.5)
                        .shadow(radius: 1)
                } else {
                    Image("brand_placeholder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .cornerRadius(22.5)
                        .shadow(radius: 1)
                }
            }
            .padding(.bottom, 6)
            Divider().opacity(0.3)
        }
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        SectionView(title: "Descripción") {
            Text(displayPerfume.description)
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Olfactory Pyramid Section
    private var olfactoryPyramidSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Pirámide Olfativa".uppercased())
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                pyramidNoteView(title: "Salida", notes: displayPerfume.topNotes)
                pyramidNoteView(title: "Corazón", notes: displayPerfume.heartNotes)
                pyramidNoteView(title: "Fondo", notes: displayPerfume.baseNotes)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cornerRadius(10)
        }
    }

    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        SectionView(title: "Recomendaciones") {
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(
                    title: "Proyección",
                    value: Projection(rawValue: displayPerfume.projection)?.displayName ?? "N/A"
                )

                DetailRow(
                    title: "Duración",
                    value: Duration(rawValue: displayPerfume.duration)?.displayName ?? "N/A"
                )

                let seasonNames = displayPerfume.recommendedSeason.compactMap { seasonKey in
                    Season(rawValue: seasonKey)?.displayName
                }.joined(separator: ", ")
                DetailRow(
                    title: "Estación",
                    value: seasonNames.isEmpty ? "N/A" : seasonNames
                )

                let occasionNames = displayPerfume.occasion.compactMap { occasionKey in
                    Occasion(rawValue: occasionKey)?.displayName
                }.joined(separator: ", ")
                DetailRow(
                    title: "Ocasión",
                    value: occasionNames.isEmpty ? "N/A" : occasionNames
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Opinion Button
    private var opinionButton: some View {
        Button(action: {
            showingEvaluationOnboarding = true
        }) {
            HStack {
                Spacer()
                Text("Mi Opinión")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color("primaryChampagne"))
            .cornerRadius(12)
        }
        .navigationDestination(isPresented: $showingEvaluationOnboarding) {
            AddPerfumeOnboardingView(
                isAddingPerfume: $isAddingPerfume,
                triedPerfumeRecord: nil,
                selectedPerfumeForEvaluation: perfume,
                configuration: OnboardingConfiguration(context: .triedPerfumeOpinion)
            )
        }
    }

    // MARK: - Toolbar Buttons
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.backward")
                .font(.title3)
                .foregroundColor(Color("textoPrincipal"))
        }
    }

    private var saveButton: some View {
        Button(action: {
            showSaveConfirmation = true
        }) {
            if isSaving {
                SpinnerView()
            } else {
                Text("Guardar")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("textoPrincipal"))
            }
        }
        .disabled(isSaving)
    }

    // MARK: - Helper Functions

    private func pyramidNoteView(title: String, notes: [String]?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title + ":")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .frame(minWidth: 70, alignment: .leading)

            Text(getNoteNames(from: notes))
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func getNoteNames(from keys: [String]?) -> String {
        guard let noteKeys = keys?.prefix(3), !noteKeys.isEmpty else {
            return "N/A"
        }

        // Fallback: Si notesViewModel.notes está vacío, usar keys directamente
        if notesViewModel.notes.isEmpty {
            return Array(noteKeys).joined(separator: ", ")
        }

        // Intentar lookup en notesViewModel
        let names = noteKeys.compactMap { key -> String? in
            notesViewModel.notes.first { $0.key == key }?.name
        }

        if names.isEmpty {
            return Array(noteKeys).joined(separator: ", ")
        }

        return names.joined(separator: ", ")
    }

    private func DetailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title + ":")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .frame(minWidth: 70, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))

            Spacer()
        }
    }

    // MARK: - Data Loading

    private func loadFullPerfume() async {
        // Si el perfume ya tiene descripción completa, no necesitamos recargarlo
        if !perfume.description.isEmpty && perfume.topNotes?.isEmpty == false {
            fullPerfume = perfume
            return
        }

        isLoadingPerfume = true

        do {
            if let loaded = try await perfumeViewModel.loadPerfumeByKey(perfume.key) {
                fullPerfume = loaded
                #if DEBUG
                print("✅ [AddPerfumeDetailView] Perfume completo cargado: \(loaded.name)")
                #endif
            } else {
                // Fallback al perfume original si no se puede cargar
                fullPerfume = perfume
                #if DEBUG
                print("⚠️ [AddPerfumeDetailView] No se pudo cargar perfume completo, usando datos básicos")
                #endif
            }
        } catch {
            fullPerfume = perfume
            #if DEBUG
            print("❌ [AddPerfumeDetailView] Error cargando perfume: \(error)")
            #endif
        }

        isLoadingPerfume = false
    }

    // MARK: - Save Logic

    private func saveBasicPerfume() async {
        guard !perfume.key.isEmpty && !perfume.brand.isEmpty else {
            #if DEBUG
            print("❌ Error: Datos de perfume incompletos para guardar (key or brand empty).")
            #endif
            return
        }

        isSaving = true

        #if DEBUG
        print("💾 [AddPerfumeDetailView] Guardando perfume con key: '\(perfume.key)'")
        #endif

        // ✅ CRITICAL FIX: Usar perfume.key en lugar de perfume.id
        // El key es el identificador único del perfume (ej: "dior_sauvage")
        // El id es el document ID de Firestore (generado automáticamente)
        await userViewModel.addTriedPerfume(
            perfumeId: perfume.key,  // ✅ Usar .key para consistencia con la búsqueda
            rating: 0,  // Sin rating inicial
            userProjection: nil,  // Sin proyección de usuario
            userDuration: nil,  // Sin duración de usuario
            userPrice: "",  // Sin precio de usuario
            notes: "",  // Sin notas
            userSeasons: [],  // Sin estaciones de usuario
            userPersonalities: []  // Sin personalidades de usuario
        )

        isSaving = false

        if userViewModel.errorMessage == nil {
            // Simply close the view
            await MainActor.run {
                isAddingPerfume = false
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            #if DEBUG
            print("Error al guardar perfume básico: \(userViewModel.errorMessage?.value ?? "Error desconocido")")
            #endif
        }
    }
}

// MARK: - Toast View Component

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 32)
    }
}

// MARK: - Spinner View Component

struct SpinnerView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color("textoPrincipal"), lineWidth: 2)
            .frame(width: 20, height: 20)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 0.8)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}
