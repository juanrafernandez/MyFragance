import SwiftUI
import Charts

struct ResultsView: View {
    @Binding var path: [String]
    var profile: [String: Double] // Los datos que se mostrarán en el gráfico

    var body: some View {
        ZStack {
            // Fondo blanco
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Título
                Text("Tu Perfil Olfativo")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color("TitleColor"))
                    .padding(.top, 16)

                // Verificación de datos y gráfico
                if profile.isEmpty {
                    Text("No hay datos disponibles")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    Chart {
                        ForEach(profile.keys.sorted(), id: \.self) { key in
                            BarMark(
                                x: .value("Porcentaje", profile[key] ?? 0),
                                y: .value("Nota", key)
                            )
                            .foregroundStyle(Color("PrimaryButtonColor"))
                            .annotation(position: .trailing) {
                                Text("\(Int(profile[key] ?? 0))%")
                                    .font(.caption)
                                    .foregroundColor(Color("TitleColor"))
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 300) // Ajustar altura del gráfico
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                Spacer()

                // Botón para volver al inicio
                Button(action: {
                    path.removeAll()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.title2)
                        Text("Volver al Inicio")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("PrimaryButtonColor"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(
            path: .constant([]),
            profile: ["Cítricas": 40, "Florales": 30, "Amaderadas": 20, "Dulces": 10]
        )
    }
}
