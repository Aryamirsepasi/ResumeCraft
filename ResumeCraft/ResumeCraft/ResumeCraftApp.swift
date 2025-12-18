//
//  ResumeCraftApp.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData
import CloudKit
import FoundationModels

@main
struct ResumeCraftApp: App {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

  @State private var openRouterSettings = OpenRouterSettings()
  @State private var openRouterProvider =
    OpenRouterProvider(config: OpenRouterSettings().config)

    // NEW: local on-device AI provider
    @State private var fmProvider = FoundationModelProvider()
    @State private var aiReviewViewModel: AIReviewViewModel

    @State private var modelContainer: ModelContainer
    @State private var persistenceStatus: PersistenceStatus
    
    @MainActor
    static func makeModelContainer() -> (ModelContainer, PersistenceStatus) {
      let schema = Schema([
        Resume.self,
        PersonalInfo.self,
        Summary.self,
        WorkExperience.self,
        Project.self,
        Skill.self,
        Education.self,
        Extracurricular.self,
        Language.self,
        ResumeHistory.self,
      ])

      do {
        let cloud = ModelConfiguration(
          schema: schema,
          cloudKitDatabase: .private(CloudKitConfiguration.containerIdentifier)
        )
        let container = try ModelContainer(for: schema, configurations: [cloud])
        return (
          container,
          PersistenceStatus(
            backend: .cloudKit(containerIdentifier: CloudKitConfiguration.containerIdentifier)
          )
        )
      } catch {
        // Important: falling back keeps the app usable, but disables sync. Surface this in Settings.
        let status = PersistenceStatus(
          backend: .local,
          cloudKitInitializationError: error.localizedDescription
        )
        do {
          // Attempt 1: default local store location (may fail if an old incompatible store exists).
          do {
            let local = ModelConfiguration(schema: schema)
            let container = try ModelContainer(for: schema, configurations: [local])
            return (container, status)
          } catch {
            // Attempt 2: a fresh store URL to bypass incompatible/corrupt previous stores.
            let recoveredStatus = PersistenceStatus(
              backend: .local,
              cloudKitInitializationError: status.cloudKitInitializationError,
              localInitializationError: error.localizedDescription
            )
            let recoveredLocal = ModelConfiguration(
              schema: schema,
              url: makeLocalStoreURL(filename: "ResumeCraftLocalRecovered.store")
            )
            let container = try ModelContainer(for: schema, configurations: [recoveredLocal])
            return (container, recoveredStatus)
          }
        } catch {
          // Last resort: in-memory store so the app can still launch.
          let lastResortStatus = PersistenceStatus(
            backend: .inMemory,
            cloudKitInitializationError: status.cloudKitInitializationError,
            localInitializationError: error.localizedDescription
          )
          let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
          do {
            let container = try ModelContainer(for: schema, configurations: [memory])
            return (container, lastResortStatus)
          } catch {
            fatalError("In-memory ModelContainer failed: \(error.localizedDescription)")
          }
        }
      }
    }

    private static func makeLocalStoreURL(filename: String) -> URL {
      let fileManager = FileManager.default
      let baseDirectory =
        (try? fileManager.url(
          for: .applicationSupportDirectory,
          in: .userDomainMask,
          appropriateFor: nil,
          create: true
        ))
        ?? fileManager.temporaryDirectory

      let bundleId = Bundle.main.bundleIdentifier ?? "ResumeCraft"
      let directory = baseDirectory.appending(path: bundleId, directoryHint: .isDirectory)
      try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      return directory.appending(path: filename, directoryHint: .notDirectory)
    }

  init() {
    //let settings = OpenRouterSettings()
    //let provider = OpenRouterProvider(config: settings.config)
    //_openRouterSettings = State(initialValue: settings)
    //_openRouterProvider = State(initialValue: provider)
    //_aiReviewViewModel = State(initialValue: AIReviewViewModel(ai: provider))
      let provider = FoundationModelProvider()
          _fmProvider = State(initialValue: provider)
          _aiReviewViewModel = State(initialValue: AIReviewViewModel(ai: provider)) // still conforms to AIProvider

      let (container, status) = Self.makeModelContainer()
      _modelContainer = State(initialValue: container)
      _persistenceStatus = State(initialValue: status)
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
      .environment(fmProvider)
      .environment(aiReviewViewModel)
      .environment(openRouterSettings)
      .environment(openRouterProvider)
      .environment(persistenceStatus)
      .overlay(AppleIntelligenceGate())
    }
    .modelContainer(modelContainer)
  }
}

// Small helper: shows a subtle banner if Apple Intelligence is unavailable.
@MainActor
private struct AppleIntelligenceGate: View {
  @Environment(\.openURL) private var openURL

  private func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    openURL(url)
  }

  var body: some View {
    let availability = SystemLanguageModel.default.availability
    if case .unavailable(let reason) = availability {
      VStack {
        Spacer()
        HStack(spacing: 12) {
          Image(systemName: "sparkles")
          Text("On-device AI is unavailable (\(String(describing: reason))). Enable Apple Intelligence in Settings.")
          Button("Open Settings") {
            openAppSettings()
          }
        }
        .font(.footnote)
        .padding(12)
        .background(.ultraThinMaterial, in: Capsule())
        .padding()
      }
      .transition(.move(edge: .bottom))
    }
  }
}
