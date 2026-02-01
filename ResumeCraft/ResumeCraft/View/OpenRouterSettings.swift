//
//  OpenRouterSettings.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 07.08.25.
//

import Foundation

@MainActor
@Observable
final class OpenRouterSettings {
  private let defaults = UserDefaults.standard
  private let keyKey = "openrouter_api_key"
  private let modelKey = "openrouter_model"

  var apiKey: String {
    didSet { defaults.set(apiKey, forKey: keyKey) }
  }
  var model: String {
    didSet { defaults.set(model, forKey: modelKey) }
  }

  init() {
    self.apiKey = defaults.string(forKey: keyKey) ?? ""
    self.model = defaults.string(forKey: modelKey) ?? OpenRouterConfig.defaultModel
  }

  var config: OpenRouterConfig {
    OpenRouterConfig(apiKey: apiKey, model: model)
  }
}
