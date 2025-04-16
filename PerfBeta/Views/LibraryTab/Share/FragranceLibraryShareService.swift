import SwiftUI
import UIKit

// Struct simple para pasar a la vista de compartir genérica
struct ShareablePerfumeItem: Identifiable {
    let id: String
    let perfume: Perfume
    let displayRating: Double? // Rating a mostrar (personal o de interés)
    let ratingType: RatingType // Para saber qué icono/color usar

    enum RatingType {
        case none
        case personal // Corazón rojo
        case interest // Estrella amarilla/gris
    }
}

@MainActor // Marcar como @MainActor porque interactúa con UI (renderizado, presentación)
class FragranceLibraryShareService {

    // Método principal y genérico para iniciar el proceso de compartir
    func share<Item: Identifiable, Content: View, Provider: FilterInformationProvider>(
        items: [Item],
        filterInfoProvider: Provider, // <<< NOMBRE Y TIPO CORRECTOS
        viewProvider: @escaping ([Item], Provider) -> Content, // <<< USA EL TIPO GENÉRICO PROVIDER
        textProvider: @escaping (Int, Provider) -> String // <<< USA EL TIPO GENÉRICO PROVIDER
    ) async {
        // ... tu implementación para generar imagen y compartir ...
        // Aquí dentro, usarías 'filterInfoProvider' para obtener los datos necesarios
        let text = textProvider(items.count, filterInfoProvider)
        let shareView = viewProvider(items, filterInfoProvider)
        
        // Lógica para renderizar shareView a una imagen (snapshot)
        guard let image = await snapshot(view: shareView) else {
            print("Error: No se pudo generar la imagen para compartir.")
            // Mostrar error al usuario
            return
        }
        
        // Lógica para presentar UIActivityViewController
        presentShareSheet(text: text, image: image)
    }
    
    // Helper para snapshot (ejemplo, adapta a tu implementación)
    private func snapshot<Content: View>(view: Content) async -> UIImage? {
        let controller = UIHostingController(rootView: view.ignoresSafeArea())
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear // O el color de fondo deseado
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    // Helper para presentar la hoja de compartir (ejemplo)
    private func presentShareSheet(text: String, image: UIImage) {
        let activityItems: [Any] = [text, image]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Encuentra la escena y la ventana adecuadas para presentar
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Error: No se pudo encontrar el ViewController para presentar la hoja de compartir.")
            return
        }
        
        // Presenta desde el ViewController raíz
        rootViewController.present(activityVC, animated: true, completion: nil)
    }

    /// Renderiza una vista SwiftUI a un UIImage usando ImageRenderer.
    private func renderViewToImage(view: some View, size: CGSize) async -> UIImage? {
        // Aplica el frame ANTES de pasar al renderer
        let framedView = view.frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: framedView)
        renderer.scale = UIScreen.main.scale
        print("ShareService: Imagen generada para compartir.")
        return renderer.uiImage
    }

    /// Muestra el UIActivityViewController (Share Sheet).
    private func showShareSheet(image: UIImage, text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("ShareService: Error: No se pudo obtener el root view controller.")
            return
        }

        let activityItems: [Any] = [image, text]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        var presentingController = rootViewController
        while let presented = presentingController.presentedViewController {
            presentingController = presented
        }

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = presentingController.view
            popoverController.sourceRect = CGRect(x: presentingController.view.bounds.midX, y: presentingController.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        print("ShareService: Presentando Share Sheet...")
        presentingController.present(activityViewController, animated: true, completion: nil)
    }
}
// --- Protocolo FilterInformationProvider (Necesario ANTES del Adapter) ---
// Asegúrate de que esta definición también exista y esté visible
protocol FilterInformationProvider {
    var selectedFilters: [String: [String]] { get }
    var perfumePopularityRange: ClosedRange<Double> { get }
    var searchText: String { get }
    // Añade ratingRange si tu ShareService o ShareView lo necesita explícitamente
    var ratingRange: ClosedRange<Double> { get }
}


// --- Adaptador para ShareService ---
// Coloca esta struct ANTES de TriedPerfumesListView
struct FilterInfoProviderAdapter<Item: FilterablePerfumeItem>: FilterInformationProvider {
    // Observa el ViewModel para obtener los datos de filtros actuales
    @ObservedObject var viewModel: FilterViewModel<Item>
    // Puede necesitar otros ViewModels si requiere lógica adicional (ej. nombres de familias)
    let familyViewModel: FamilyViewModel

    // --- Conformidad con FilterInformationProvider ---

    var selectedFilters: [String : [String]] {
        viewModel.selectedFilters
    }

    var perfumePopularityRange: ClosedRange<Double> {
        viewModel.perfumePopularityRange
    }

    var searchText: String {
        viewModel.searchText
    }

    // Expón ratingRange si tu protocolo FilterInformationProvider lo requiere
    var ratingRange: ClosedRange<Double> {
        viewModel.ratingRange
    }

    // --- Métodos Helper (Opcional pero útil) ---
    // Puedes añadir funciones aquí para obtener datos formateados si ShareView los necesita
    func getFamilyNames(keys: [String]) -> [String] {
        keys.compactMap { key in familyViewModel.familias.first { $0.key == key }?.name ?? key }
    }

    func getGenderNames(keys: [String]) -> [String] {
        keys.compactMap { Gender(rawValue: $0)?.displayName ?? $0 }
    }

    func getSeasonNames(keys: [String]) -> [String] {
        keys.compactMap { Season(rawValue: $0)?.displayName ?? $0 }
    }
}
