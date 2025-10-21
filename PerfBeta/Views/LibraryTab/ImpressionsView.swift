import SwiftUI
import Foundation

struct ImpressionsView: View {
    let selectedPerfume: Perfume
    @Binding var userImpressions: String
    let onSave: () -> Void
    @Environment(\.presentationMode) var presentationMode // For programmatic dismissal

    // Estados para los valores seleccionados
    @State private var rating: Double = 5.0 // Inicializado en 5 para que el slider empiece en el centro
    @State private var duration: Duration? = nil
    @State private var intensity: Intensity? = nil
    @State private var season: Season? = nil

    var body: some View {
        NavigationView { // Embed the content in a NavigationView
            ScrollView {
                VStack {
                    // Información del perfume seleccionado
                    HStack {
                        Image(selectedPerfume.imageURL ?? "placeholder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        VStack(alignment: .leading) {
                            Text(selectedPerfume.name)
                                .font(.headline)
                            Text(selectedPerfume.brand)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.white) // Added background for better visual separation
                    .cornerRadius(10)
                    .shadow(radius: 2)


                    // Slider para la puntuación
                    VStack(alignment: .leading) {
                        Text("Puntuación (0-10): \(String(format: "%.1f", rating))")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Slider(value: $rating, in: 0...10, step: 0.5)
                    }
                    .padding()
                    .background(.white) // Added background for better visual separation
                    .cornerRadius(10)
                    .shadow(radius: 2)


                    // Duración
                    VStack(alignment: .leading) {
                        Text("Duración:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Picker("Duración", selection: $duration) {
                            Text("Seleccionar").tag(nil as Duration?) // Add a "None" option
                            ForEach(Duration.allCases) { durationOption in // Explicit type annotation is implicit
                                Text(durationOption.displayName).tag(durationOption as Duration?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)

                    }
                    .padding()
                    .background(.white) // Added background for better visual separation
                    .cornerRadius(10)
                    .shadow(radius: 2)



                    // Intensidad
                    VStack(alignment: .leading) {
                        Text("Intensidad del olor:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Picker("Intensidad", selection: $intensity) {
                            Text("Seleccionar").tag(nil as Intensity?)
                            ForEach(Intensity.allCases) { intensityOption in
                                Text(intensityOption.displayName).tag(intensityOption as Intensity?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)

                    }
                    .padding()
                    .background(.white) // Added background for better visual separation
                    .cornerRadius(10)
                    .shadow(radius: 2)


                    // Época del año
                    VStack(alignment: .leading) {
                        Text("Época del año recomendada:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Picker("Época del año", selection: $season) {
                            Text("Seleccionar").tag(nil as Season?)
                            ForEach(Season.allCases) { seasonOption in
                                Text(seasonOption.displayName).tag(seasonOption as Season?)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(.white) // Added background for better visual separation
                    .cornerRadius(10)
                    .shadow(radius: 2)


                    // Cuadro para escribir impresiones
                    VStack(alignment: .leading) {
                        Text("Impresiones:")
                            .font(.headline)
                            .padding(.bottom, 5)
                        TextEditor(text: $userImpressions)
                            .frame(minHeight: 100)
                            .border(Color.gray, width: 1)
                    }
                    .padding()
                    .background(.white) // Added background for better visual separation
                    .cornerRadius(10)
                    .shadow(radius: 2)


                    // Botón Guardar
                    AppButton(
                        title: "Guardar",
                        action: {
                            // Aquí puedes acceder a rating, duration, intensity, season, userImpressions
                            print("Rating: \(rating)")
                            print("Duration: \(duration?.rawValue ?? "Ninguna")")
                            print("Intensity: \(intensity?.rawValue ?? "Ninguna")")
                            print("Season: \(season?.rawValue ?? "Ninguna")")
                            print("Impressions: \(userImpressions)")
                            onSave() // Llama a la función onSave después de obtener los valores
                        },
                        style: .accent,
                        size: .large,
                        isFullWidth: true,
                        icon: "checkmark.circle.fill"
                    )
                    .padding(.horizontal)

                }
                .padding()
            }
            .background(Color("fondoClaro").edgesIgnoringSafeArea(.all))
            .navigationTitle("Añadir Impresiones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {  // Use toolbar to add navigation bar items
                ToolbarItem(placement: .navigationBarTrailing) { // Place the button on the right
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }) {
                        Image(systemName: "xmark") // Use the "X" icon
                    }
                }
            }
        }
    }
}
