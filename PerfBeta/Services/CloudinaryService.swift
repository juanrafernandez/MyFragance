import Cloudinary
import UIKit

class CloudinaryService {
    private let cloudinary: CLDCloudinary

    init() {
        // Validate secrets are configured before attempting to use Cloudinary
        do {
            try Secrets.validate()
        } catch {
            // Log error but don't crash - service will fail gracefully when used
            print("⚠️ Cloudinary configuration error: \(error.localizedDescription)")
            print("⚠️ Please ensure Secrets.swift is properly configured")
        }

        // Use centralized Secrets configuration
        let config = CLDConfiguration(
            cloudName: Secrets.cloudinaryCloudName,
            apiKey: Secrets.cloudinaryAPIKey,
            apiSecret: Secrets.cloudinaryAPISecret
        )
        self.cloudinary = CLDCloudinary(configuration: config)

        print("✅ CloudinaryService initialized with cloud: \(Secrets.cloudinaryCloudName)")
    }
    
    // Subir una imagen
    func uploadImage(_ image: UIImage, for id: UUID) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo convertir la imagen a JPEG"])
        }

        let uploadParams = CLDUploadRequestParams()
        uploadParams.setFolder("perfumesImages")

        let uploader = cloudinary.createUploader()
        return try await withCheckedThrowingContinuation { continuation in
            uploader.upload(data: imageData, uploadPreset: "perfumes_upload", params: uploadParams, completionHandler: { result, error in
                if let error = error {
                    print("Error al subir la imagen: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let url = result?.secureUrl {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibió una URL válida"]))
                }
            })
        }
    }
    
    // Eliminar una imagen
    func deleteImage(publicId: String) async throws {
        let managementApi = cloudinary.createManagementApi()
        let params = CLDDestroyRequestParams().setResourceType("image")
        var publicIdWithFolfder = "perfumesImages/\(publicId)"
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            managementApi.destroy(publicIdWithFolfder, params: params) { result, error in
                if let error = error {
                    print("Error al eliminar la imagen: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let result = result, result.result == "ok" {
                    print("Imagen eliminada con éxito.")
                    continuation.resume()
                } else {
                    let error = NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo eliminar la imagen."])
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Extraer el Public ID de una URL
    private func extractPublicId(from url: String) -> String? {
        guard let components = URL(string: url)?.pathComponents else {
            return nil
        }
        guard let lastComponent = components.last else {
            return nil
        }
        let publicIdWithExtension = lastComponent
        let publicId = publicIdWithExtension.components(separatedBy: ".").dropLast().joined(separator: ".")
        return publicId
    }
}

extension CloudinaryService {
    func deleteImage(from url: String) async throws {
        guard let publicId = extractPublicId(from: url) else {
            throw NSError(domain: "CloudinaryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo extraer el Public ID de la URL proporcionada"])
        }
        try await deleteImage(publicId: publicId)
    }
}
