//
//  AIProviderSelection.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 07.08.25.
//

import Foundation

enum AIBackend: String, CaseIterable, Identifiable {
  case localMLX
  case openRouter

  var id: String { rawValue }
  var displayName: String {
    switch self {
    case .localMLX: return "Local (MLX)"
    case .openRouter: return "OpenRouter (Cloud)"
    }
  }
}

@Observable
final class AIProviderSelection {
  private let defaults = UserDefaults.standard
  private let key = "ai_backend_selection"
  var backend: AIBackend {
    didSet { defaults.set(backend.rawValue, forKey: key) }
  }

  init() {
    if let raw = defaults.string(forKey: key), let b = AIBackend(rawValue: raw) {
      backend = b
    } else {
      backend = .localMLX
    }
  }
}
