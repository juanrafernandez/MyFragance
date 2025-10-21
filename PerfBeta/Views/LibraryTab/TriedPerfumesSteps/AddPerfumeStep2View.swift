import SwiftUI

struct AddPerfumeStep2View: View {
    let selectedPerfume: Perfume
    @Binding var isAddingPerfume: Bool
    @Binding var showingEvaluationOnboarding: Bool
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Detalles del perfume (Familia, Subfamilias, Género, Pirámide Olfativa, Descripción, etc.)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Familia Olfativa:").font(.headline)
                    Text(selectedPerfume.family).foregroundColor(.secondary)
                }

                if !selectedPerfume.subfamilies.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Subfamilias:").font(.headline)
                        Text(selectedPerfume.subfamilies.joined(separator: ", ")).foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Género:").font(.headline)
                    Text(getGenderDisplayName(selectedPerfume.gender)).foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Pirámide Olfativa:").font(.headline)
                    if let topNotes = selectedPerfume.topNotes, !topNotes.isEmpty {
                        Text("Salida: \(topNotes.joined(separator: ", "))").foregroundColor(.secondary)
                    }
                    if let heartNotes = selectedPerfume.heartNotes, !heartNotes.isEmpty {
                        Text("Corazón: \(heartNotes.joined(separator: ", "))").foregroundColor(.secondary)
                    }
                    if let baseNotes = selectedPerfume.baseNotes, !baseNotes.isEmpty {
                        Text("Base: \(baseNotes.joined(separator: ", "))").foregroundColor(.secondary)
                    }
                    if (selectedPerfume.topNotes == nil || selectedPerfume.topNotes!.isEmpty) && (selectedPerfume.heartNotes == nil || selectedPerfume.heartNotes!.isEmpty) && (selectedPerfume.baseNotes == nil || selectedPerfume.baseNotes!.isEmpty) {
                        Text("No especificada").foregroundColor(.gray)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Descripción:").font(.headline)
                    Text(selectedPerfume.description).foregroundColor(.secondary)
                }

                if let year = selectedPerfume.year, year > 0 {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Año de Lanzamiento:").font(.headline)
                        Text("\(year)").foregroundColor(.secondary)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Perfumista:").font(.headline)
                    Text(selectedPerfume.perfumist ?? "No especificado").foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { // Button action remains the same
                   showingEvaluationOnboarding = true
                }) {
                    Rectangle() // Make the whole button area tappable
                        .fill(.champan) // Make the rectangle invisible
                        .frame(maxWidth: .infinity, minHeight: 50) // Ensure a tappable area, minHeight for accessibility
                        .cornerRadius(12)
                        .buttonStyle(PlainButtonStyle())
                        .overlay(Text("Evaluar") // Overlay the styled Text on top
                            .foregroundColor(.white)
                            .padding()
                        )
                }
            }
            .padding()
        }
        .navigationTitle("Información del Perfume")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.backward")
                    .foregroundColor(.black)
            }
        )
        .navigationBarItems(trailing:
                Button("Guardar") {
                    Task {
                        await saveBasicPerfume()
                    }
                }
        )
        .navigationDestination(isPresented: $showingEvaluationOnboarding) {
            AddPerfumeOnboardingView(isAddingPerfume: $isAddingPerfume, triedPerfumeRecord: nil, initialStep: 3, selectedPerfumeForEvaluation: selectedPerfume)
        }
    }

    private func saveBasicPerfume() async {
        guard  !selectedPerfume.key.isEmpty && !selectedPerfume.brand.isEmpty else {
            print("Error: Datos de perfume incompletos para guardar (key or brand empty).")
            return
        }
        let perfumeIdString = selectedPerfume.id
        let perfumeKey = selectedPerfume.key
        let brandId = selectedPerfume.brand
        
       await userViewModel.addTriedPerfume(
           perfumeId: perfumeIdString,
           perfumeKey: perfumeKey,
           brandId: brandId,
           projection: selectedPerfume.projection,
           duration: selectedPerfume.duration,
           price: selectedPerfume.price ?? "",
           rating: selectedPerfume.popularity ?? 0.0,
           impressions: "",
           occasions: selectedPerfume.occasion,
           seasons: selectedPerfume.recommendedSeason,
           personalities: selectedPerfume.associatedPersonalities
       )

       if userViewModel.errorMessage == nil {
           isAddingPerfume = false
       } else {
           print("Error al guardar perfume básico: \(userViewModel.errorMessage?.value ?? "Error desconocido")")
       }
   }

    private func getGenderDisplayName(_ genderRawValue: String) -> String {
        if let gender = Gender(rawValue: genderRawValue) {
            return gender.displayName
        } else {
            return "No especificado"
        }
    }
}
