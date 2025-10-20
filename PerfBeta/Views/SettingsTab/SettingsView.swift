import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    // State para mostrar un diálogo de confirmación/información
    @State private var showingClearCacheAlert = false
    @State private var clearCacheMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        // --- SECCIÓN CUENTA ---
                        SectionCard(title: "Cuenta", content: {
                            Button(action: {
                                print("SettingsView: Botón Cerrar sesión presionado.")
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
                            Button(action: {
                                print("SettingsView: Botón Limpiar Caché presionado.")
                                // Llama a la función auxiliar para limpiar la caché
                                clearCache()
                            }) {
                                HStack {
                                    // Puedes usar otro icono si prefieres: "eraser.line.dashed.fill"
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.orange) // Un color distinto para destacar
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
                               print("Escribir al desarrollador")
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

                        // --- SECCIÓN PERSONALIZACIÓN ---
                       SectionCard(title: "Personalización del Degradado", content: {
                           Picker("", selection: $selectedGradientPreset) {
                               ForEach(GradientPreset.allCases, id: \.self) { preset in
                                   Text(preset.rawValue).tag(preset)
                               }
                           }
                           .pickerStyle(SegmentedPickerStyle())
                           .cornerRadius(8)
                           .padding(.vertical, 4)
                       })
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
        }
    }

    // --- FUNCIÓN AUXILIAR PARA LLAMAR AL APPDELEGATE ---
    func clearCache() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ SettingsView: No se pudo obtener la instancia de AppDelegate.")
            clearCacheMessage = "Error interno al intentar limpiar la caché."
            showingClearCacheAlert = true
            return
        }

        print("⚙️ SettingsView: Solicitando limpieza de caché al AppDelegate...")
        appDelegate.clearFirestoreCache()

        // Informamos al usuario que la acción se ha solicitado.
        // El resultado real se ve en la consola (según tu implementación actual).
        clearCacheMessage = "Se ha solicitado la limpieza de la caché. Cierra y vuelve a abrir la app si experimentas problemas. Puedes ver detalles en la consola de depuración."
        showingClearCacheAlert = true
    }
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
