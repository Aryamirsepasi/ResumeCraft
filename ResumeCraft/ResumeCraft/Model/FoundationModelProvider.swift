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
  private var sessionInstructions: String?
  private var currentTask: Task<String, Error>?

  init() {}

  private func makeSession(instructions: String?) -> LanguageModelSession {
    let normalizedInstructions = instructions?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    if let existing = session, normalizedInstructions == sessionInstructions {
      return existing
    }

    let newSession: LanguageModelSession
    if let normalizedInstructions, !normalizedInstructions.isEmpty {
      newSession = LanguageModelSession(instructions: normalizedInstructions)
    } else {
      newSession = LanguageModelSession()
    }

    session = newSession
    sessionInstructions = normalizedInstructions
    return newSession
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
          "Apple Intelligence ist nicht verfügbar: \(String(describing: reason)). " +
          "Aktiviere Apple Intelligence in den Einstellungen, um die On-Device-Prüfung zu nutzen."]
      )
    }

    let germanLocale = Locale(identifier: "de_DE")
    if !SystemLanguageModel.default.supportsLocale(germanLocale) {
      throw NSError(
        domain: "FoundationModels",
        code: -3,
        userInfo: [NSLocalizedDescriptionKey:
          "Das installierte Sprachmodell unterstützt Deutsch nicht. " +
          "Bitte installiere eine deutsche Systemsprachunterstützung oder wähle ein anderes Modell."]
      )
    }

    let session = makeSession(instructions: systemPrompt)

    let task = Task { () async throws -> String in
      let response = try await session.respond(to: userPrompt)
      try Task.checkCancellation()
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
