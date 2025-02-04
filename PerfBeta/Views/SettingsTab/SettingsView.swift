import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                // Sección de cuenta
                Section(header: Text("Cuenta")) {
                    Button(action: {
                        // Acción para cerrar sesión
                        print("Cerrar sesión")
                    }) {
                        HStack {
                            Image(systemName: "person.fill.xmark")
                                .foregroundColor(.red)
                            Text("Cerrar sesión")
                        }
                    }
                }

                // Sección de soporte
                Section(header: Text("Soporte")) {
                    Button(action: {
                        // Acción para escribir al desarrollador
                        print("Escribir al desarrollador")
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Escribir al desarrollador")
                        }
                    }
                }

                // Sección de información
                Section(header: Text("Información")) {
                    HStack {
                        Text("Versión de la App")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .listStyle(InsetGroupedListStyle()) // Estilo moderno
        }
    }
}
