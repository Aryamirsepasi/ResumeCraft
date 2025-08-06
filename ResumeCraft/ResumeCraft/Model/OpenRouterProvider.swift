
import Foundation
import UIKit
import AIProxy

struct OpenRouterConfig: Codable, Equatable {
  var apiKey: String
  var model: String
  static let defaultModel = "openai/gpt-4o-mini"
}

@MainActor
@Observable
final class OpenRouterProvider: AIProvider {
    
    
  var isProcessing = false

  private var config: OpenRouterConfig
  private var aiProxyService: OpenRouterService?
  private var currentTask: Task<Void, Never>?

  init(config: OpenRouterConfig) {
    self.config = config
    setupAIProxyService()
  }

  func updateConfig(_ newConfig: OpenRouterConfig) {
    guard newConfig != config else { return }
    self.config = newConfig
    setupAIProxyService()
  }

  private func setupAIProxyService() {
    guard !config.apiKey.isEmpty else {
      aiProxyService = nil
      return
    }
    aiProxyService = AIProxy.openRouterDirectService(unprotectedAPIKey: config.apiKey)
  }

  func processText(
    systemPrompt: String? = "You are a helpful writing assistant.",
    userPrompt: String,
    images: [Data] = [],
    streaming: Bool = false
  ) async throws -> String {
    isProcessing = true
    defer { isProcessing = false }

    guard !config.apiKey.isEmpty else {
      throw NSError(
        domain: "OpenRouterAPI",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "API key is missing."]
      )
    }

    if aiProxyService == nil {
      setupAIProxyService()
    }

    guard let openRouterService = aiProxyService else {
      throw NSError(
        domain: "OpenRouterAPI",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AIProxy service."]
      )
    }

    // Only text messages. We ignore images here (we use Apple Vision elsewhere).
    var messages: [OpenRouterChatCompletionRequestBody.Message] = []
    if let systemPrompt, !systemPrompt.isEmpty {
      messages.append(.system(content: .text(systemPrompt)))
    }
    messages.append(.user(content: .text(userPrompt)))

    let modelName = config.model.isEmpty ? OpenRouterConfig.defaultModel : config.model

    let requestBody = OpenRouterChatCompletionRequestBody(
      messages: messages,
      models: [modelName],
      route: .fallback
    )

    do {
      if streaming {
        var compiledResponse = ""
        let stream = try await openRouterService.streamingChatCompletionRequest(
          body: requestBody
        )
        for try await chunk in stream {
          if Task.isCancelled { break }
          if let content = chunk.choices.first?.delta.content {
            compiledResponse += content
          }
        }
        return compiledResponse
      } else {
        let response = try await openRouterService.chatCompletionRequest(body: requestBody)
        return response.choices.first?.message.content ?? ""
      }
    } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
      throw NSError(
        domain: "OpenRouterAPI",
        code: statusCode,
        userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"]
      )
    } catch {
      throw error
    }
  }

  func cancel() {
    currentTask?.cancel()
    currentTask = nil
    isProcessing = false
  }
}
