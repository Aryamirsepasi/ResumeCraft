//
//  FoundationModelProvider.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 18.09.25.
//

// FoundationModelProvider.swift
import Foundation
import Observation

import FoundationModels   // iOS 26+; add to target’s frameworks

@MainActor
@Observable
final class FoundationModelProvider: AIProvider {
  var isProcessing = false
  private var session: LanguageModelSession?
  private var currentTask: Task<String, Error>?

  init() {}

  private func makeSession(instructions: String?) -> LanguageModelSession {
    if let s = session { return s }
    if let instructions, !instructions.isEmpty {
      session = LanguageModelSession(instructions: instructions)
    } else {
      session = LanguageModelSession()
    }
    return session!
  }

  func processText(
    systemPrompt: String?,
    userPrompt: String,
    images: [Data] = [],
    streaming: Bool = false
  ) async throws -> String {
    // Cancel any in-flight work
    currentTask?.cancel()
    isProcessing = true
    defer { isProcessing = false; currentTask = nil }

    // Ensure availability (user may have Apple Intelligence disabled)
    switch SystemLanguageModel.default.availability {
    case .available: break
    case .unavailable(let reason):
      throw NSError(
        domain: "FoundationModels",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey:
          "Apple Intelligence model unavailable: \(String(describing: reason)). " +
          "Enable Apple Intelligence in Settings to use on-device review."]
      )
    }

    let session = makeSession(instructions: systemPrompt)

    // (Most of the app uses non-streaming today; keep simple & reliable.)
    // You can later adopt streamResponse(to:) when you want incremental UI.
    let task = Task.detached { () async throws -> String in
      let response = try await session.respond(to: userPrompt)
      return response.content
    }
    currentTask = task
    return try await task.value
  }

  func cancel() {
    currentTask?.cancel()
    currentTask = nil
    isProcessing = false
  }
}
