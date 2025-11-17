import Foundation
import FirebaseFirestore

/// Service responsible for parsing Question objects from Firestore documents.
/// Eliminates code duplication between TestService and QuestionsService.
protocol QuestionParserProtocol {
    func parseQuestion(from document: QueryDocumentSnapshot) -> Question?
}

class QuestionParser: QuestionParserProtocol {

    // MARK: - Public Methods

    /// Parses a Question from a Firestore document
    /// - Parameter document: The Firestore document snapshot
    /// - Returns: A parsed Question, or nil if parsing fails
    func parseQuestion(from document: QueryDocumentSnapshot) -> Question? {
        let data = document.data()

        guard let category = data["category"] as? String,
              let text = data["text"] as? String,
              let key = data["key"] as? String,
              let questionType = data["questionType"] as? String,
              let order = data["order"] as? Int else {
            return nil
        }

        // Parse optional fields for evaluation questions
        let stepType = data["stepType"] as? String
        let multiSelect = data["multiSelect"] as? Bool

        // Parse options array
        let optionsArray = data["options"] as? [[String: Any]] ?? []
        let options = optionsArray.compactMap { parseOption(from: $0) }

        return Question(
            id: data["id"] as? String ?? document.documentID,
            key: key,
            questionType: questionType,
            order: order,
            category: category,
            text: text,
            stepType: stepType,
            multiSelect: multiSelect,
            options: options,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
        )
    }

    // MARK: - Private Methods

    /// Parses an Option from a dictionary
    /// - Parameter optionDict: Dictionary containing option data
    /// - Returns: A parsed Option, or nil if parsing fails
    private func parseOption(from optionDict: [String: Any]) -> Option? {
        // Handle 'id' field as optional - generate UUID if not present
        let id = optionDict["id"] as? String ?? UUID().uuidString

        guard let label = optionDict["label"] as? String,
              let value = optionDict["value"] as? String,
              let description = optionDict["description"] as? String,
              let imageAsset = optionDict["image_asset"] as? String,
              let families = optionDict["families"] as? [String: Int] else {
            return nil
        }

        // Parse optional route field for flow routing
        let route = optionDict["route"] as? String

        return Option(
            id: id,
            label: label,
            value: value,
            description: description,
            image_asset: imageAsset,
            families: families,
            route: route
        )
    }
}
