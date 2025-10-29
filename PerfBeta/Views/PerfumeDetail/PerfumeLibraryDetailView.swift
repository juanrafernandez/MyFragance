import SwiftUI
import Kingfisher
import Combine

// MARK: - PerfumeLibraryDetailView - Restructured Detail View based on ExploreTabView
struct PerfumeLibraryDetailView: View {
    let perfume: Perfume
    let triedPerfume: TriedPerfume  // ✅ REFACTOR: Nuevo modelo

    @Environment(\.dismiss) var dismiss // Para cerrar el fullScreenCover

    //@State private var currentTriedPerfume: TriedPerfume
    @State private var isEditingPerfume = false // State to control the fullScreenCover
    // ✅ ELIMINADO: Sistema de temas personalizable // Default preset

    // Initialize with perfumeWithRecord
    init(perfume: Perfume, triedPerfume: TriedPerfume) {
        self.perfume = perfume
        self.triedPerfume = triedPerfume
        //self.currentTriedPerfume = State(initialValue: triedPerfume)
    }

    var body: some View {
        NavigationView { // Embed in NavigationView
            ZStack {
                // Gradient background
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        headerSection
                        olfactoryDetailsSection
                        descriptionSection
                        userExperienceSection
                        additionalDetailsSection
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 15)
                    .padding(.bottom, 25)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 0)
                }
            }
            .navigationTitle("Detalle del Perfume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
        }
        .fullScreenCover(isPresented: $isEditingPerfume) {
            AddPerfumeInitialStepsView(isAddingPerfume: $isEditingPerfume, perfumeToEdit: perfume)
                .onDisappear { // Reload data on disappear - MODIFIED
                    Task {
                        //currentPerfumeWithRecord = await reloadTriedPerfumeRecord() ?? currentPerfumeWithRecord
                    }
                }
        }
        .onAppear { // Initial load on appear - MODIFIED
            Task {
                //currentPerfumeWithRecord = await reloadTriedPerfumeRecord() ?? currentPerfumeWithRecord // Use local reload function
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center) {
            // ✅ Fix: Don't pass asset name as URL string - let URL(string:) return nil for invalid URLs
            // Perfume Image
            KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                .placeholder { Image("placeholder").resizable().scaledToFit() }
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.bottom, 10)

            // Perfume Name and Brand
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(perfume.name) // Use currentPerfumeWithRecord
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("textoPrincipal"))
                        .lineLimit(2)

                    Text(perfume.brand ?? "") // Use currentPerfumeWithRecord - Fallback for brand
                        .font(.title2)
                        .foregroundColor(Color("textoSecundario"))
                }
                Spacer()
                Image("brand_placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .cornerRadius(22.5)
                    .shadow(radius: 1)
            }
            .padding(.bottom, 6)

            Divider().opacity(0.3)
        }
    }

    // MARK: - Olfactory Details Section
    private var olfactoryDetailsSection: some View {
        SectionView(title: "Familia Olfativa, Pirámide Olfativa y Género") {
            VStack(alignment: .leading, spacing: 8) {
                DetailRowMinimalist(label: "Familia Olfativa", value: perfume.family)
                DetailRowMinimalist(label: "Subfamilias", value: perfume.subfamilies.joined(separator: ", "))
                DetailRowMinimalist(label: "Género", value: getGenderDisplayName(perfume.gender))
                NotesRowMinimalist(title: "Notas de Salida", notes: perfume.topNotes)
                NotesRowMinimalist(title: "Notas de Corazón", notes: perfume.heartNotes)
                NotesRowMinimalist(title: "Notas de Base", notes: perfume.baseNotes)
            }
            .padding(.bottom, 10)
        }
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        SectionView(title: "Descripción") {
            Text(perfume.description)
                .font(.body)
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.leading)
                .padding(.bottom, 12)
        }
    }

    // MARK: - User Experience Section
    private var userExperienceSection: some View {
        SectionView(title: "Mi Experiencia Personal") {
            VStack(alignment: .leading, spacing: 8) {
                // ✅ REFACTOR: rating no es opcional, userProjection/userDuration/userPrice sí lo son
                DetailRowMinimalist(label: "Puntuación", value: String(format: "%.1f / 5", triedPerfume.rating))
                DetailRowMinimalist(label: "Proyección (Usuario)", value: getProjectionDisplayName(triedPerfume.userProjection))
                DetailRowMinimalist(label: "Duración (Usuario)", value: getDurationDisplayName(triedPerfume.userDuration))
                DetailRowMinimalist(label: "Precio (Usuario)", value: getPriceDisplayName(triedPerfume.userPrice))
                DetailRowMinimalist(label: "Impresiones", value: triedPerfume.notes ?? "")
            }
            .padding(.bottom, 10)
        }
    }

    // MARK: - Additional Details Section
    private var additionalDetailsSection: some View {
        SectionView(title: "Más Detalles") {
            VStack(alignment: .leading, spacing: 8) {
                DetailRowMinimalist(label: "Intensidad", value: getIntensityDisplayName(perfume.intensity))
                DetailRowMinimalist(label: "Duración (Definida)", value: getDurationDisplayName(perfume.duration))
                DetailRowMinimalist(label: "Proyección (Definida)", value: getProjectionDisplayName(perfume.projection))
                DetailRowMinimalist(label: "Ocasión Recomendada", value: perfume.occasion.compactMap { Occasion(rawValue: $0) }.map { getOccasionDisplayName($0) }.joined(separator: ", "))
                DetailRowMinimalist(label: "Temporada Recomendada", value: perfume.recommendedSeason.compactMap { Season(rawValue: $0) }.map { getSeasonDisplayName($0) }.joined(separator: ", "))
                DetailRowMinimalist(label: "Personalidades Asociadas", value: perfume.associatedPersonalities.compactMap { Personality(rawValue: $0) }.map { getPersonalityDisplayName($0) }.joined(separator: ", "))
                DetailRowMinimalist(label: "Precio (Definido)", value: getPriceDisplayName(perfume.price))
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Close Button
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(Color("textoPrincipal"))
        }
    }

    // MARK: - Edit Button
    private var editButton: some View {
        Button("Editar") {
            isEditingPerfume = true
        }
    }

    // Helper functions to get display names safely (No changes needed)
    private func getGenderDisplayName(_ genderRawValue: String) -> String {
        if let gender = Gender(rawValue: genderRawValue) {
            return gender.displayName
        } else {
            return "No especificado"
        }
    }

    private func getProjectionDisplayName(_ projectionRawValue: String?) -> String {
        if let projectionValue = projectionRawValue, let projection = Projection(rawValue: projectionValue) {
            return projection.displayName
        } else {
            return "No especificado"
        }
    }

    private func getDurationDisplayName(_ durationRawValue: String?) -> String {
        if let durationValue = durationRawValue, let duration = Duration(rawValue: durationValue) {
            return duration.displayName
        } else {
            return "No especificado"
        }
    }

    private func getPriceDisplayName(_ priceRawValue: String?) -> String {
        if let priceValue = priceRawValue, let price = Price(rawValue: priceValue) {
            return price.displayName
        } else {
            return "No especificado"
        }
    }

    private func getIntensityDisplayName(_ intensityRawValue: String?) -> String {
        if let intensityValue = intensityRawValue, let intensity = Intensity(rawValue: intensityValue) {
            return intensity.displayName
        } else {
            return "No especificada"
        }
    }

    private func getOccasionDisplayName(_ occasion: Occasion) -> String {
        return occasion.displayName
    }

    private func getSeasonDisplayName(_ season: Season) -> String {
        return season.displayName
    }

    private func getPersonalityDisplayName(_ personality: Personality) -> String {
        return personality.displayName
    }
}

// MARK: - Helper Views for Detail View - Minimalist Style (No changes needed)
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color("textoPrincipal"))
    }
}

struct DetailRowMinimalist: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color("textoPrincipal"))
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}

struct NotesRowMinimalist: View {
    let title: String
    let notes: [String]?
    var body: some View {
        HStack(alignment: .top) { // Changed VStack to HStack, aligning to top
            Text(title + ":") // Added ":" to the title to match DetailRowMinimalist
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color("textoPrincipal"))
            if let notes = notes, !notes.isEmpty {
                Text(notes.joined(separator: ", "))
                    .font(.system(size: 13))
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.leading) // Added multilineTextAlignment for longer notes
            } else {
                Text("No especificado")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading) // Added multilineTextAlignment for longer "No especificado"
                Spacer() // Keep Spacer to push content to the left
            }
        }
    }
}
