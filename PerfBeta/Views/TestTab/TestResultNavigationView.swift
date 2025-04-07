import SwiftUI

struct TestResultNavigationView: View {
    let profile: OlfactiveProfile
    @Binding var isTestActive: Bool
    
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isSavePopupVisible = false
    @State private var saveName: String = ""
    
    var body: some View {
        VStack {
            TestResultContentView(profile: profile)
                .navigationTitle("Perfil generado")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true) // Ocultar el botón de retroceso predeterminado
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                        }
                    }
                }
                .sheet(isPresented: $isSavePopupVisible) {
                    SaveProfileView(
                        profile: profile,
                        saveName: $saveName,
                        isSavePopupVisible: $isSavePopupVisible,
                        isTestActive: $isTestActive
                    )
                }
            
            // Botón de Guardar
            saveButton
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            isSavePopupVisible = true
        }) {
            Text("Guardar Perfil")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#F6AD55"))
                .foregroundColor(.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}
