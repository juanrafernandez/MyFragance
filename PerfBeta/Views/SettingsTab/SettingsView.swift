import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Cuenta", content: {
                            Button(action: {
                                print("Cerrar sesión")
                            }) {
                                HStack {
                                    Image(systemName: "person.fill.xmark")
                                        .foregroundColor(.red)
                                    Text("Cerrar sesión")
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading) // Alinea el texto a la izquierda
                                }
                            }
                            .buttonStyle(MinimalButtonStyle())
                        })

                        SectionCard(title: "Soporte", content: {
                            Button(action: {
                                print("Escribir al desarrollador")
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                    Text("Escribir al desarrollador")
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading) // Alinea el texto a la izquierda
                                }
                            }
                            
                        })

                        SectionCard(title: "Información", content: {
                            HStack {
                                Text("Versión de la App")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.gray)
                            }
                        })

                        SectionCard(title: "Personalización del Degradado", content: {
                            Picker("", selection: $selectedGradientPreset) {
                                ForEach(GradientPreset.allCases, id: \.self) { preset in
                                    Text(preset.rawValue).tag(preset)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.vertical, 4)
                        })
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

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
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MinimalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}


