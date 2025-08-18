import Foundation
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

  func requestFeedback() async {
    isGenerating = true
    feedback = nil
    errorMessage = nil

    let prompt = """
    Act as a professional resume reviewer.
    Given the following resume section and job description, suggest specific, \
    measurable improvements for clarity, ATS optimization, and impact.

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
