//
//  AIRouter.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 07.08.25.
//

// AIRouter.swift

import Foundation

@MainActor
@Observable
final class AIRouter: AIProvider {
  var isProcessing: Bool = false

  private let mlx: MLXService
  private let openRouter: OpenRouterProvider
  private let selection: AIProviderSelection

  init(
    mlxService: MLXService,
    openRouterProvider: OpenRouterProvider,
    selection: AIProviderSelection
  ) {
    self.mlx = mlxService
    self.openRouter = openRouterProvider
    self.selection = selection
  }

  func processText(
    systemPrompt: String?,
    userPrompt: String,
    images: [Data],
    streaming: Bool
  ) async throws -> String {
    switch selection.backend {
    case .localMLX:
      // Build a temporary Thread; reuse MLXService.generate
      let thread = Thread(title: "AI")
      if let system = systemPrompt, !system.isEmpty {
        thread.addMessage(Message(content: system, role: .system))
      }
      thread.addMessage(Message(content: userPrompt, role: .user))
      isProcessing = true
      defer { isProcessing = false }
      return await mlx.generate(thread: thread)
    case .openRouter:
      isProcessing = true
      defer { isProcessing = false }
      return try await openRouter.processText(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        images: [], // ignore images here; Apple Vision is handled elsewhere
        streaming: streaming
      )
    }
  }

  func cancel() {
    switch selection.backend {
    case .localMLX:
      mlx.stopGeneration()
    case .openRouter:
      openRouter.cancel()
    }
    isProcessing = false
  }
}
