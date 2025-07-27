import Foundation
import MLXLMCommon
import SwiftUI

@MainActor
@Observable
final class AIReviewViewModel {
    private let mlxService: MLXService

    init(mlxService: MLXService) {
        self.mlxService = mlxService
    }

    var jobDescription: String = ""
    var resumeSection: String = ""

    var feedback: String?
    var isGenerating = false
    var errorMessage: String?

    var selectedModelId: String {
        UserDefaults.standard.string(forKey: "selectedLLMName") ?? "mlx-community/gemma-2-2b-it-4bit"
    }

    func requestFeedback() async {
        isGenerating = true
        feedback = nil
        errorMessage = nil

        if let aiModel = AIModelsRegistry.shared.modelById(selectedModelId) {
            ModelManager.shared.setActiveModel(aiModel.configuration)
        } else {
            ModelManager.shared.setActiveModel(AIModelsRegistry.shared.defaultModel.configuration)
        }

        let prompt =
        """
        Act as a professional resume reviewer.
        Given the following resume section and job description, suggest specific, measurable improvements for clarity, ATS optimization, and impact.

        Resume section:
        \(resumeSection)

        Job description:
        \(jobDescription)
        """

        let thread = Thread(title: "Resume Review")
        let systemMessage = Message(content: "You are a professional resume reviewer and ATS expert.", role: .system)
        let userMessage = Message(content: prompt, role: .user)
        thread.addMessage(systemMessage)
        thread.addMessage(userMessage)

        do {
            let result = await mlxService.generate(thread: thread)
            feedback = result
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
