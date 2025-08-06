//
//  ResumeCraftApp.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData

@main
struct ResumeCraftApp: App {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

  // Shared SwiftData container
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Resume.self, PersonalInfo.self, WorkExperience.self,
      Project.self, Skill.self, Education.self,
      Extracurricular.self, Language.self,
    ])
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  // Shared AI dependencies (singletons for the process lifetime)
  @State private var providerSelection = AIProviderSelection()
  @State private var openRouterSettings = OpenRouterSettings()
  @State private var mlxService = MLXService()
  @State private var openRouterProvider =
    OpenRouterProvider(config: OpenRouterSettings().config)
  @State private var aiRouter: AIRouter

  init() {
    // Build the router once using shared state objects
    let selection = AIProviderSelection()
    let settings = OpenRouterSettings()
    let mlx = MLXService()
    let open = OpenRouterProvider(config: settings.config)
    _providerSelection = State(initialValue: selection)
    _openRouterSettings = State(initialValue: settings)
    _mlxService = State(initialValue: mlx)
    _openRouterProvider = State(initialValue: open)
    _aiRouter = State(
      initialValue: AIRouter(
        mlxService: mlx,
        openRouterProvider: open,
        selection: selection
      )
    )
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if hasSeenOnboarding {
          ResumeRootView()
        } else {
          OnboardingFlow(hasSeenOnboarding: $hasSeenOnboarding)
        }
      }
      // Inject shared AI environment objects
      .environment(providerSelection)
      .environment(openRouterSettings)
      .environment(openRouterProvider)
      .environment(mlxService)
      .environment(aiRouter)
      // Keep OpenRouterProvider in sync with settings
      .task {
        openRouterProvider.updateConfig(openRouterSettings.config)
      }
    }
    .modelContainer(sharedModelContainer)
  }
}
