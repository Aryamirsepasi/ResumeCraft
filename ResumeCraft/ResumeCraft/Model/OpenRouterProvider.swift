import Foundation
import AIProxy
import Observation

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
  private var currentTask: Task<String, Error>?

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
    aiProxyService = AIProxy.openRouterDirectService(
      unprotectedAPIKey: config.apiKey
    )
  }

  func processText(
    systemPrompt: String? = "You are a helpful writing assistant.",
    userPrompt: String,
    images: [Data] = [],
    streaming: Bool = false
  ) async throws -> String {
    // Cancel any previous in-flight task
    currentTask?.cancel()
    isProcessing = true
    defer {
      isProcessing = false
      currentTask = nil
    }

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

    guard let service = aiProxyService else {
      throw NSError(
        domain: "OpenRouterAPI",
        code: -1,
        userInfo: [
          NSLocalizedDescriptionKey: "Failed to initialize AIProxy service."
        ]
      )
    }

    var messages: [OpenRouterChatCompletionRequestBody.Message] = []
    if let systemPrompt, !systemPrompt.isEmpty {
      messages.append(.system(content: .text(systemPrompt)))
    }
    messages.append(.user(content: .text(userPrompt)))

    let modelName =
      config.model.isEmpty ? OpenRouterConfig.defaultModel : config.model

    let requestBody = OpenRouterChatCompletionRequestBody(
      messages: messages,
      models: [modelName],
      route: .fallback
    )

    let task = Task.detached { () throws -> String in
      do {
        if streaming {
          var compiledResponse = ""
          let stream = try await service.streamingChatCompletionRequest(
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
          let response = try await service.chatCompletionRequest(body: requestBody)
          if Task.isCancelled { throw CancellationError() }
          return response.choices.first?.message.content ?? ""
        }
      } catch AIProxyError.unsuccessfulRequest(let statusCode, let responseBody) {
        throw NSError(
          domain: "OpenRouterAPI",
          code: statusCode,
          userInfo: [NSLocalizedDescriptionKey: "API error: \(responseBody)"]
        )
      }
    }

    currentTask = task

    do {
      return try await task.value
    } catch is CancellationError {
      // Return empty string on cancel; caller can decide how to handle it.
      return ""
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
