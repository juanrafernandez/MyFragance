import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    // ✅ ELIMINADO: Sistema de temas personalizable para mantener identidad de marca única

    // State para mostrar un diálogo de confirmación/información
    @State private var showingClearCacheAlert = false
    @State private var clearCacheMessage = ""

    #if DEBUG
    @State private var isAddingB3Questions = false
    @State private var b3QuestionsMessage = ""
    @State private var showingB3QuestionsAlert = false
    #endif

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        // --- SECCIÓN CUENTA ---
                        SectionCard(title: "Cuenta", content: {
                            Button(action: {
                                #if DEBUG
                                print("SettingsView: Botón Cerrar sesión presionado.")
                                #endif
                                authViewModel.signOut()
                            }) {
                                HStack {
                                    Image(systemName: "person.fill.xmark")
                                        .foregroundColor(.red)
                                    Text("Cerrar sesión")
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .buttonStyle(MinimalButtonStyle())
                        })

                        // --- NUEVA SECCIÓN: DATOS ---
                        SectionCard(title: "Datos", content: {
                            // ✅ Estadísticas de Caché
                            CacheStatsView()
                                .padding(.bottom, 8)

                            Divider()
                                .padding(.vertical, 8)

                            // Botón Limpiar Caché
                            Button(action: {
                                #if DEBUG
                                print("SettingsView: Botón Limpiar Caché presionado.")
                                #endif
                                // Llama a la función auxiliar para limpiar la caché
                                clearCache()
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.orange)
                                    Text("Limpiar caché local")
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .buttonStyle(MinimalButtonStyle())
                        })
                        // --- FIN NUEVA SECCIÓN ---


                        // --- SECCIÓN SOPORTE ---
                        SectionCard(title: "Soporte", content: {
                           Button(action: {
                               #if DEBUG
                               print("Escribir al desarrollador")
                               #endif
                               // Lógica para abrir email/formulario
                           }) {
                               HStack {
                                   Image(systemName: "envelope.fill")
                                       .foregroundColor(.blue)
                                   Text("Escribir al desarrollador")
                                       .foregroundColor(.primary)
                                       .frame(maxWidth: .infinity, alignment: .leading)
                               }
                           }
                           .buttonStyle(MinimalButtonStyle())
                       })

                        // --- SECCIÓN INFORMACIÓN ---
                       SectionCard(title: "Información", content: {
                           HStack {
                               Text("Versión de la App")
                                   .foregroundColor(.secondary)
                               Spacer()
                               Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                                   .foregroundColor(.gray)
                           }
                       })

                        #if DEBUG
                        // --- SECCIÓN DEBUG ---
                        SectionCard(title: "🐛 DEBUG", content: {
                            // Botón para añadir preguntas B3
                            Button(action: {
                                print("SettingsView: Botón Añadir Preguntas B3 presionado.")
                                addB3Questions()
                            }) {
                                HStack {
                                    if isAddingB3Questions {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    Text("Añadir Preguntas B3")
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .buttonStyle(MinimalButtonStyle())
                            .disabled(isAddingB3Questions)

                            Text("⚠️ Ejecutar solo una vez para añadir las 4 preguntas del flujo B3 a Firebase")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        })
                        #endif

                        // ✅ ELIMINADO: Sección "Personalización del Degradado"
                        // Para mantener identidad de marca consistente
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            // Adjuntamos el .alert aquí para que esté disponible
            .alert(isPresented: $showingClearCacheAlert) {
                Alert(title: Text("Limpieza de Caché"), message: Text(clearCacheMessage), dismissButton: .default(Text("OK")))
            }
            #if DEBUG
            .alert(isPresented: $showingB3QuestionsAlert) {
                Alert(title: Text("Preguntas B3"), message: Text(b3QuestionsMessage), dismissButton: .default(Text("OK")))
            }
            #endif
        }
    }

    // --- FUNCIÓN AUXILIAR PARA LLAMAR AL APPDELEGATE ---
    func clearCache() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            #if DEBUG
            print("❌ SettingsView: No se pudo obtener la instancia de AppDelegate.")
            #endif
            clearCacheMessage = "Error interno al intentar limpiar la caché."
            showingClearCacheAlert = true
            return
        }

        #if DEBUG
        print("⚙️ SettingsView: Solicitando limpieza de caché al AppDelegate...")
        #endif
        appDelegate.clearFirestoreCache()

        // Informamos al usuario que la acción se ha solicitado.
        // El resultado real se ve en la consola (según tu implementación actual).
        clearCacheMessage = "Se ha solicitado la limpieza de la caché. Cierra y vuelve a abrir la app si experimentas problemas. Puedes ver detalles en la consola de depuración."
        showingClearCacheAlert = true
    }

    #if DEBUG
    func addB3Questions() {
        isAddingB3Questions = true
        b3QuestionsMessage = ""

        Task {
            do {
                print("⚙️ SettingsView: Ejecutando addFlowB3Questions()...")
                try await GiftQuestionService.shared.addFlowB3Questions()

                await MainActor.run {
                    isAddingB3Questions = false
                    b3QuestionsMessage = "✅ Las 4 preguntas del flujo B3 se han añadido correctamente a Firebase.\n\nPreguntas añadidas:\n- flowB3_02_intensity\n- flowB3_03_moment\n- flowB3_04_personal_style\n- flowB3_05_budget\n\nEl cache se ha invalidado automáticamente."
                    showingB3QuestionsAlert = true

                    print("✅ SettingsView: Preguntas B3 añadidas correctamente")
                }
            } catch {
                await MainActor.run {
                    isAddingB3Questions = false
                    b3QuestionsMessage = "❌ Error al añadir preguntas B3:\n\(error.localizedDescription)"
                    showingB3QuestionsAlert = true

                    print("❌ SettingsView: Error añadiendo preguntas B3: \(error)")
                }
            }
        }
    }
    #endif
}

// --- CÓDIGO DE SectionCard y MinimalButtonStyle (sin cambios) ---

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            content
        }
        .padding()
        .background(Color.white.opacity(0.1)) // Considera ajustar opacidad si es necesario
        .cornerRadius(12)
    }
}

struct MinimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16) // Ajusta si el texto es muy largo
            .background(Color.white.opacity(0.2)) // Considera ajustar opacidad
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
