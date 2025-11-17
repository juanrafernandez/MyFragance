import SwiftUI

struct TestResultNavigationView: View {
    let profile: OlfactiveProfile
    @Binding var isTestActive: Bool

    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isSavePopupVisible = false
    @State private var saveName: String = ""
    @State private var showCloseConfirmation = false
    @State private var hasBeenSaved = false

    var body: some View {
        NavigationStack {
            UnifiedResultsView(
                profile: profile,
                isTestActive: $isTestActive,
                onSave: nil,  // Ya no necesitamos este botón en el listado
                onRestartTest: {
                    // Reiniciar test - el cambio de isTestActive cerrará automáticamente
                    testViewModel.resetTest()
                    isTestActive = true
                }
            )
            .navigationTitle("Tu Perfil Olfativo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                logCompleteProfile()
            }
            .toolbar {
                // Botón X de cerrar a la izquierda
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if hasBeenSaved {
                            isTestActive = false
                        } else {
                            showCloseConfirmation = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color("textoPrincipal"))
                    }
                }

                // Botón Guardar a la derecha
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSavePopupVisible = true
                    }) {
                        Text("Guardar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("champan"))
                    }
                }
            }
            .alert("¿Salir sin guardar?", isPresented: $showCloseConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Salir sin guardar", role: .destructive) {
                    isTestActive = false
                }
            } message: {
                Text("Si sales ahora, perderás los resultados de tu test olfativo. ¿Estás seguro?")
            }
            .sheet(isPresented: $isSavePopupVisible) {
                SaveProfileView(
                    profile: profile,
                    saveName: $saveName,
                    isSavePopupVisible: $isSavePopupVisible,
                    isTestActive: $isTestActive,
                    onSaved: {
                        hasBeenSaved = true
                    }
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Logging

    private func logCompleteProfile() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 PERFIL OLFATIVO COMPLETO")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        // Información básica
        print("\n📋 INFORMACIÓN BÁSICA:")
        print("   ID: \(profile.id ?? "Sin ID")")
        print("   Nombre: \(profile.name)")
        print("   Género: \(profile.gender)")
        print("   Orden: \(profile.orderIndex)")
        if let experienceLevel = profile.experienceLevel {
            print("   Nivel Experiencia: \(experienceLevel)")
        }

        // Características
        print("\n✨ CARACTERÍSTICAS:")
        print("   Intensidad: \(profile.intensity)")
        print("   Duración: \(profile.duration)")
        if let description = profile.descriptionProfile {
            print("   Descripción: \(description)")
        }
        if let icon = profile.icon {
            print("   Icono: \(icon)")
        }

        // Sistema de calidad (si existe unifiedProfile en el TestViewModel)
        if let unifiedProfile = testViewModel.unifiedProfile {
            print("\n📊 CALIDAD DEL PERFIL:")
            print("   Confianza: \(String(format: "%.2f", unifiedProfile.confidenceScore)) (\(Int(unifiedProfile.confidenceScore * 100))%)")
            print("   Completitud: \(String(format: "%.2f", unifiedProfile.answerCompleteness)) (\(Int(unifiedProfile.answerCompleteness * 100))%)")
            print("   Nivel experiencia: \(unifiedProfile.experienceLevel.rawValue)")

            // Metadata adicional
            print("\n📝 METADATA:")
            if let notes = unifiedProfile.metadata.preferredNotes, !notes.isEmpty {
                print("   Notas preferidas: \(notes.joined(separator: ", "))")
            }
            if let perfumes = unifiedProfile.metadata.referencePerfumes, !perfumes.isEmpty {
                print("   Perfumes de referencia: \(perfumes.joined(separator: ", "))")
            }
            if let avoid = unifiedProfile.metadata.avoidFamilies, !avoid.isEmpty {
                print("   Familias a evitar: \(avoid.joined(separator: ", "))")
            }
            if let seasons = unifiedProfile.metadata.preferredSeasons, !seasons.isEmpty {
                print("   Temporadas preferidas: \(seasons.joined(separator: ", "))")
            }
            if let occasions = unifiedProfile.metadata.preferredOccasions, !occasions.isEmpty {
                print("   Ocasiones: \(occasions.joined(separator: ", "))")
            }
            if let personalities = unifiedProfile.metadata.personalityTraits, !personalities.isEmpty {
                print("   Rasgos de personalidad: \(personalities.joined(separator: ", "))")
            }
        }

        // Familias
        print("\n🌿 FAMILIAS OLFATIVAS:")
        for (index, familyPuntuation) in profile.families.enumerated() {
            let familyInfo = familyViewModel.getFamily(byKey: familyPuntuation.family)
            let familyName = familyInfo?.name ?? familyPuntuation.family
            print("   [\(index + 1)] \(familyName)")
            print("       Key: \(familyPuntuation.family)")
            print("       Puntuación: \(familyPuntuation.puntuation)")
        }

        // Preguntas y Respuestas
        if let questionsAndAnswers = profile.questionsAndAnswers {
            print("\n❓ PREGUNTAS Y RESPUESTAS (\(questionsAndAnswers.count) total):")
            for (index, qa) in questionsAndAnswers.enumerated() {
                print("   [\(index + 1)] Pregunta ID: \(qa.questionId)")
                print("       Respuesta ID: \(qa.answerId)")
                print("")
            }
        } else {
            print("\n❓ PREGUNTAS Y RESPUESTAS: No disponibles")
        }

        // Perfumes recomendados
        if let recommendedPerfumes = profile.recommendedPerfumes {
            print("\n🎯 PERFUMES RECOMENDADOS (\(recommendedPerfumes.count) total):")
            for (index, rec) in recommendedPerfumes.enumerated() {
                print("   [\(index + 1)] Perfume ID: \(rec.perfumeId)")
                print("       Coincidencia: \(String(format: "%.1f%%", rec.matchPercentage))")
                print("")
            }
        } else {
            print("\n🎯 PERFUMES RECOMENDADOS: No disponibles")
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ FIN DEL PERFIL")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
}
