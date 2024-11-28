import SwiftUI
import Charts

struct ResultsView: View {
    @Binding var path: [String]
    var profile: [String: Double]

    var body: some View {
        VStack {
            Text("Tu Perfil Olfativo")
                .font(.title)
                .padding()
                .foregroundColor(.black)

            Chart {
                ForEach(profile.keys.sorted(), id: \.self) { key in
                    BarMark(
                        x: .value("Porcentaje", profile[key] ?? 0),
                        y: .value("Nota", key)
                    )
                    .foregroundStyle(Color.blue) // Colores oscuros para mayor visibilidad
                    .annotation(position: .trailing) {
                        Text("\(Int(profile[key] ?? 0))%")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: CGFloat(profile.keys.count) * 50) // Ajusta la altura dinámica
            .padding()
            .background(Color.cyan)

            Spacer()

            // Botón para volver al inicio
            Button(action: {
                path.removeAll() // Vacía el stack de navegación
            }) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.title2)
                    Text("Volver al Inicio")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(
            path: .constant([]),
            profile: ["Cítricas": 40, "Florales": 30, "Amaderadas": 20, "Dulces": 10]
        )
        .background(Color.black)
    }
}
