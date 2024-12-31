import SwiftUI

struct SuggestionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profileManager: OlfactiveProfileManager // Manager global de perfiles
    @EnvironmentObject var familiaOlfativaManager: FamiliaOlfativaManager

    @Binding var isTestActive: Bool
    let questions: [Question]
    let answers: [String: Option]

    @State private var profile: String
    @State private var complementaryProfile: String
    @State private var suggestedPerfumes: [Perfume]
    @State private var profileName: String = ""
    @State private var showSavePrompt = false

    init(isTestActive: Binding<Bool>, questions: [Question], answers: [String: Option]) {
        self._isTestActive = isTestActive
        self.questions = questions
        self.answers = answers

        let profileResult = Self.calculateProfile(from: answers)
        self._profile = State(initialValue: profileResult.profile)
        self._complementaryProfile = State(initialValue: profileResult.complementaryProfile)
        self._suggestedPerfumes = State(initialValue: Self.suggestPerfumes(for: profileResult))
    }

    var body: some View {
        VStack {
            // Título del perfil olfativo
            Text("Tu Perfil Olfativo")
                .font(.headline)
                .padding(.top)

            Text(profile)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Complementado por \(complementaryProfile)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            // Lista de perfumes sugeridos
            List(suggestedPerfumes) { perfume in
                HStack {
                    Image(perfume.image_name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(perfume.nombre)
                            .font(.headline)
                        Text(perfume.fabricante)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(PlainListStyle())

            // Botón para guardar el perfil olfativo
            Button(action: {
                showSavePrompt = true
            }) {
                Text("Guardar Perfil Olfativo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("champan"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()

            Spacer()
        }
        .navigationBarBackButtonHidden(true) // Ocultar botón de volver
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                    isTestActive = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("Guardar Perfil", isPresented: $showSavePrompt) {
            TextField("Nombre del perfil (máx. 15 caracteres)", text: $profileName)
                .onReceive(profileName.publisher.collect()) {
                    profileName = String($0.prefix(15)) // Limitar a 15 caracteres
                }
            Button("Guardar") {
                saveProfile()
                dismiss()
                isTestActive = false
            }
            Button("Cancelar", role: .cancel) { }
        }
    }

    private func saveProfile() {
        // Obtener el ID de la familia desde el primer perfume sugerido
        let familiaId = suggestedPerfumes.first?.familia ?? "personalizada"

        // Buscar la familia usando el manager
        let familia = familiaOlfativaManager.getFamilia(byID: familiaId) ?? FamiliaOlfativa(
            id: "personalizada",
            nombre: "Personalizado",
            descripcion: "Perfil personalizado creado automáticamente.",
            notasClave: [],
            ingredientesAsociados: [],
            intensidadPromedio: "Media",
            estacionRecomendada: [],
            personalidadAsociada: [],
            color: "#CCCCCC" // Color predeterminado
        )

        // Crear el nuevo perfil usando los datos de la familia
        let newProfile = OlfactiveProfile(
            name: profileName,
            perfumes: suggestedPerfumes,
            familia: familia,
            description: familia.descripcion,
            icon: "icon_default" // Usa un ícono predeterminado o ajusta según sea necesario
        )

        // Agregar el perfil al manager de perfiles
        profileManager.addProfile(newProfile)
    }

    private static func calculateProfile(from answers: [String: Option]) -> (profile: String, complementaryProfile: String) {
        let families = answers.values.compactMap { $0.familiasAsociadas?.keys.first }
        let profile = families.mostFrequent() ?? "Desconocido"
        let complementaryProfile = families.last ?? "Desconocido"
        return (profile, complementaryProfile)
    }

    private static func suggestPerfumes(for profileResult: (profile: String, complementaryProfile: String)) -> [Perfume] {
        return MockPerfumes.perfumes.filter {
            $0.familia == profileResult.profile || $0.familia == profileResult.complementaryProfile
        }
    }
}
