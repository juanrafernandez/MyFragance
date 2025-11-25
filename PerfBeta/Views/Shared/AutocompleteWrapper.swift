import SwiftUI

/// Wrapper genérico para componentes de autocomplete
/// Maneja la sincronización bidireccional entre el ViewModel y el componente de UI
struct AutocompleteWrapper<Content: View>: View {
    @ObservedObject var viewModel: UnifiedQuestionFlowViewModel
    let question: UnifiedQuestion

    @State private var selectedKeys: [String] = []
    @State private var searchText: String = ""
    @State private var didSkip: Bool = false

    let contentBuilder: (
        _ selectedKeys: Binding<[String]>,
        _ searchText: Binding<String>,
        _ didSkip: Binding<Bool>,
        _ question: UnifiedQuestion
    ) -> Content

    var body: some View {
        contentBuilder(
            $selectedKeys,
            $searchText,
            $didSkip,
            question
        )
        .onAppear {
            selectedKeys = viewModel.getSelectedOptions()
            searchText = viewModel.getTextInput()
            didSkip = selectedKeys.contains("skip")
        }
        .onChange(of: selectedKeys) { _, newValue in
            viewModel.selectMultipleOptions(newValue)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.inputText(newValue)
        }
        .onChange(of: didSkip) { _, newValue in
            if newValue {
                viewModel.selectMultipleOptions(["skip"])
            }
        }
    }
}
