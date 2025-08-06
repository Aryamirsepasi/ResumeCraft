// AIReviewViewModel.swift

import Foundation
import MLXLMCommon
import SwiftUI

@MainActor
@Observable
final class AIReviewViewModel {
    private let ai: any AIProvider

    init(ai: any AIProvider) {
    self.ai = ai
  }

  var jobDescription: String = ""
  var resumeSection: String = ""

  var feedback: String?
  var isGenerating = false
  var errorMessage: String?

  // Keep this for MLX path, but router will handle backend
  var selectedModelId: String {
    UserDefaults.standard.string(forKey: "selectedLLMName")
      ?? "mlx-community/gemma-2-2b-it-4bit"
  }

  func requestFeedback() async {
    isGenerating = true
    feedback = nil
    errorMessage = nil

    // If local MLX is selected, ensure active model is set
    if ModelManager.shared.activeModel == nil,
       let defaultAIModel = AIModelsRegistry.shared.modelById(selectedModelId) ??
         AIModelsRegistry.shared.modelById(AIModelsRegistry.shared.defaultModel.id) {
      ModelManager.shared.setActiveModel(defaultAIModel.configuration)
    }

    let prompt = """
    Act as a professional resume reviewer.
    Given the following resume section and job description, suggest specific, measurable improvements for clarity, ATS optimization, and impact.

    Resume section:
    \(resumeSection)

    Job description:
    \(jobDescription)
    """

    do {
      let result = try await ai.processText(
        systemPrompt: "You are a professional resume reviewer and ATS expert.",
        userPrompt: prompt,
        images: [],
        streaming: false
      )
      feedback = result
    } catch {
      errorMessage = error.localizedDescription
    }

    isGenerating = false
  }
}
