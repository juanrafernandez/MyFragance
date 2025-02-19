import SwiftUI
import Combine

// MARK: - AddPerfumeOnboardingView (Sin cambios en este archivo)
struct AddPerfumeOnboardingView: View {
    @Binding var isAddingPerfume: Bool
    @State private var onboardingStep = 1
    @State private var selectedPerfume: Perfume? = nil
    @State private var duration: Duration? = nil
    @State private var projection: Projection = .defaultValue
    @State private var price: Price? = nil // State para el nuevo paso de Precio
    @State private var impressions: String = ""
    @State private var ratingValue: Double = 5.0
    @State private var showingConfirmation = false

    @Environment(\.presentationMode) var presentationMode

    @StateObject private var perfumeViewModel = PerfumeViewModel()

    let stepCount = 5 // Total steps now 5

    var body: some View {
        NavigationView {
            VStack {
                ProgressView("Paso \(onboardingStep) de \(stepCount)", value: Double(onboardingStep), total: Double(stepCount))
                    .padding(.bottom)

                ZStack {
                    VStack {
                        switch onboardingStep {
                        case 1:
                            AddPerfumeStep1View(selectedPerfume: $selectedPerfume, perfumeViewModel: perfumeViewModel, onboardingStep: $onboardingStep)
                        case 2:
                            AddPerfumeStep2View(duration: $duration, onboardingStep: $onboardingStep)
                        case 3:
                            AddPerfumeStep3View(projection: $projection, onboardingStep: $onboardingStep)
                        case 4:
                            AddPerfumeStep4View(price: $price, onboardingStep: $onboardingStep) // Nuevo paso 4: Precio
                        case 5:
                            AddPerfumeStep5View(impressions: $impressions, ratingValue: $ratingValue) // Ahora paso 5
                        default:
                            Text("Error: Paso desconocido")
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    VStack {
                        Spacer()
                        if onboardingStep > 1 && onboardingStep < 4 { // Ocultar "Continuar" hasta el paso 4
                            EmptyView() // No "Continuar" button in steps before step 4
                        } else if onboardingStep == 5 { // "Guardar" en el último paso (ahora paso 5)
                            Button("Guardar") {
                                // TODO: Guardar la valoración del perfume (usar los State variables: selectedPerfume, duration, projection, price, impressions, ratingValue)
                                isAddingPerfume = false
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    await perfumeViewModel.loadInitialData()
                }
            }
            .navigationBarTitle(navigationTitleForStep(onboardingStep), displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Group {
                    if onboardingStep == 1 {
                        Button(action: { showingConfirmation = true }) {
                            Image(systemName: "xmark")
                        }
                    } else if onboardingStep > 1 {
                        Button(action: { onboardingStep -= 1 }) {
                            Image(systemName: "arrow.backward")
                        }
                    }
                },
                trailing: EmptyView()
            )
            .alert(isPresented: $showingConfirmation) {
                confirmationAlert()
            }
            .alert(item: $perfumeViewModel.errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.value), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func navigationTitleForStep(_ step: Int) -> String {
        switch step {
        case 1:
            return "Selecciona Perfume"
        case 2:
            return "Duración"
        case 3:
            return "Proyección"
        case 4:
            return "Precio" // Título para el nuevo paso 4
        case 5:
            return "Impresiones y Valoración" // Ahora paso 5
        default:
            return ""
        }
    }

    private func confirmationAlert() -> Alert {
        Alert(
            title: Text("¿Seguro que quieres salir?"),
            message: Text("Los cambios no guardados se perderán."),
            primaryButton: .destructive(Text("Salir sin guardar")) {
                isAddingPerfume = false
            },
            secondaryButton: .cancel(Text("Cancelar"))
        )
    }
}

// MARK: - AddPerfumeStep1View (Sin cambios)
struct AddPerfumeStep1View: View {
    @Binding var selectedPerfume: Perfume?
    @ObservedObject var perfumeViewModel: PerfumeViewModel
    @Binding var onboardingStep: Int

    @State private var searchText: String = ""
    private let itemsPerPage = 20

    var body: some View {
        VStack {
            TextField("Buscar perfume o marca", text: $searchText)
                .padding(7)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal)

            if perfumeViewModel.isLoading {
                ProgressView("Cargando perfumes...")
            } else if !perfumeViewModel.perfumes.isEmpty {
                ScrollView {
                    LazyVStack {
                        ForEach(filteredPerfumes(), id: \.id) { perfume in
                            PerfumeCardRow(perfume: perfume)
                                .onTapGesture {
                                    selectedPerfume = perfume
                                    onboardingStep += 1
                                }
                            Divider()
                        }
                        if !perfumeViewModel.isLoading {
                            ProgressView("Cargando más perfumes...")
                                .onAppear {
                                    print("Cargando más perfumes - Funcionalidad no implementada en este ejemplo")
                                }
                        }
                    }
                }
            } else if perfumeViewModel.errorMessage != nil {
                Text("Error al cargar los perfumes. Por favor, inténtalo de nuevo.")
                    .foregroundColor(.red)
            } else {
                Text("No se encontraron perfumes.")
                    .foregroundColor(.gray)
            }
        }
    }

    private func filteredPerfumes() -> [Perfume] {
        if searchText.isEmpty {
            return perfumeViewModel.perfumes
        } else {
            return perfumeViewModel.perfumes.filter { perfume in
                perfume.name.localizedCaseInsensitiveContains(searchText) ||
                perfume.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - PerfumeCardRow (Sin cambios)
struct PerfumeCardRow: View {
    let perfume: Perfume

    var body: some View {
        HStack {
            Image(perfume.imageURL ?? "placeholder")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(perfume.name)
                    .font(.headline)
                    .foregroundColor(Color("textoPrincipal"))
                Text(perfume.brand)
                    .font(.subheadline)
                    .foregroundColor(Color("textoSecundario"))
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}


// MARK: - AddPerfumeStep2View (Sin cambios)
struct AddPerfumeStep2View: View {
    @Binding var duration: Duration?
    @Binding var onboardingStep: Int

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Duration.allCases, id: \.self) { durationCase in
                DurationRadioButtonRow(duration: durationCase, selectedDuration: $duration, onboardingStep: $onboardingStep)
            }
        }
    }
}

// MARK: - DurationRadioButtonRow (Sin cambios)
struct DurationRadioButtonRow: View {
    let duration: Duration
    @Binding var selectedDuration: Duration?
    @Binding var onboardingStep: Int

    var body: some View {
        HStack {
            Button(action: {
                selectedDuration = self.duration
                onboardingStep += 1
            }) {
                HStack {
                    Circle()
                        .fill(selectedDuration == self.duration ? Color("colorPrimary") : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )

                    VStack(alignment: .leading) {
                        Text(duration.displayName)
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        Text(duration.description)
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}


// MARK: - AddPerfumeStep3View (Sin cambios)
struct AddPerfumeStep3View: View {
    @Binding var projection: Projection
    @Binding var onboardingStep: Int

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                ForEach(Projection.allCases, id: \.self) { projectionCase in
                    ProjectionRadioButtonRow(projection: projectionCase, selectedProjection: $projection, onboardingStep: $onboardingStep)
                }
            }
            .frame(height: geometry.size.height, alignment: .top)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - ProjectionRadioButtonRow (Sin cambios)
struct ProjectionRadioButtonRow: View {
    let projection: Projection
    @Binding var selectedProjection: Projection
    @Binding var onboardingStep: Int

    var body: some View {
        HStack {
            Button(action: {
                selectedProjection = projection
                onboardingStep += 1
            }) {
                HStack {
                    Circle()
                        .fill(selectedProjection == projection ? Color("colorPrimary") : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )

                    VStack(alignment: .leading) {
                        Text(projection.displayName)
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        Text(projection.description)
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - AddPerfumeStep4View (Sin cambios)
struct AddPerfumeStep4View: View {
    @Binding var price: Price?
    @Binding var onboardingStep: Int

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                Text("Paso 4: Selecciona el Precio") // Título del paso
                    .font(.headline)
                    .padding(.bottom)

                ForEach(Price.allCases, id: \.self) { priceCase in
                    PriceRadioButtonRow(price: priceCase, selectedPrice: $price, onboardingStep: $onboardingStep)
                }
            }
            .frame(height: geometry.size.height, alignment: .top)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - PriceRadioButtonRow (Sin cambios)
struct PriceRadioButtonRow: View {
    let price: Price
    @Binding var selectedPrice: Price?
    @Binding var onboardingStep: Int

    var body: some View {
        HStack {
            Button(action: {
                selectedPrice = price
                onboardingStep += 1
            }) {
                HStack {
                    Circle()
                        .fill(selectedPrice == price ? Color("colorPrimary") : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )

                    VStack(alignment: .leading) {
                        Text(price.displayName)
                            .font(.headline)
                            .foregroundColor(Color("textoPrincipal"))
                        Text(price.description)
                            .font(.subheadline)
                            .foregroundColor(Color("textoSecundario"))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}


// MARK: - AddPerfumeStep5View (MODIFICADA - Layout de Impresiones y Valoración)
struct AddPerfumeStep5View: View {
    @Binding var impressions: String
    @Binding var ratingValue: Double

    var body: some View {
        VStack(alignment: .leading) { // Alineación leading para el título "Impresiones"
            Text("Paso 5: Impresiones y Valoración")
                .font(.headline)
                .padding(.bottom)

            Text("Impresiones") // Título "Impresiones" alineado a la izquierda
                .font(.subheadline)
                .foregroundColor(Color("textoPrincipal"))
                .padding(.leading) // Añade un poco de padding si es necesario

            TextEditor(text: $impressions)
                .frame(height: 100)
                .border(Color.gray, width: 0.5)
                .padding(.bottom)

            VStack(alignment: .leading) { // VStack para alinear el slider y su texto a la izquierda
                HStack {
                    Text("Valoración (0-10):")
                    Spacer() // Empuja el texto "Valoración" a la izquierda y el Slider a la derecha
                }
                Slider(value: $ratingValue, in: 0...10, step: 0.1) // Slider con step de 0.1
                Text("\(String(format: "%.1f", ratingValue))/10") // Muestra la valoración con 1 decimal
                    .frame(maxWidth: .infinity, alignment: .trailing) // Alinea el texto de valoración a la derecha
                    .padding(.trailing) // Añade un poco de padding si es necesario
            }
        }
    }
}
