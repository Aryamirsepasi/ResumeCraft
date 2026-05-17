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
  private var currentTask: Task<String, Error>?
  private var currentTaskID: UUID?

  init() {}

  private func makeSession(instructions: String?, language: ResumeLanguage) -> LanguageModelSession {
    let locale = language.locale
    let localeHint = "The person's locale is \(locale.identifier)."

    let normalizedInstructions = instructions?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let fullInstructions: String
    if let normalizedInstructions, !normalizedInstructions.isEmpty {
      fullInstructions = "\(localeHint)\n\n\(normalizedInstructions)"
    } else {
      fullInstructions = localeHint
    }

    return LanguageModelSession(instructions: fullInstructions)
  }

  func processText(
    systemPrompt: String?,
    userPrompt: String,
    images: [Data] = [],
    language: ResumeLanguage = .defaultContent,
    streaming: Bool = false
  ) async throws -> String {
    // Cancel any in-flight work
    currentTask?.cancel()
    isProcessing = true

    switch SystemLanguageModel.default.availability {
    case .available: break
    case .unavailable(let reason):
      let template = String(localized: "ai.error.appleIntelligenceUnavailable")
      isProcessing = false
      throw NSError(
        domain: "FoundationModels",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey:
          String(format: template, String(describing: reason))]
      )
    }

    let session = makeSession(instructions: systemPrompt, language: language)

    let taskID = UUID()
    let task = Task { () async throws -> String in
      let response = try await session.respond(to: userPrompt)
      try Task.checkCancellation()
      return response.content
    }
    currentTaskID = taskID
    currentTask = task
    defer {
      if currentTaskID == taskID {
        isProcessing = false
        currentTask = nil
        currentTaskID = nil
      }
    }
    return try await task.value
  }

  func cancel() {
    currentTask?.cancel()
    currentTask = nil
    currentTaskID = nil
    isProcessing = false
  }
}
