import Foundation
import Observation


@MainActor
protocol AIProvider {
  var isProcessing: Bool { get set }

  func processText(
    systemPrompt: String?,
    userPrompt: String,
    images: [Data],
    streaming: Bool
  ) async throws -> String

  func cancel()
}

