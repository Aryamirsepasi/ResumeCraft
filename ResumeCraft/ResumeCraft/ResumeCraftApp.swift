//
//  ResumeCraftApp.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData
import CloudKit
import CoreData
import FoundationModels
import os

@main
struct ResumeCraftApp: App {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // NEW: local on-device AI provider
    @State private var fmProvider = FoundationModelProvider()
    @State private var aiReviewViewModel: AIReviewViewModel

    @State private var modelContainer: ModelContainer
    @State private var persistenceStatus: PersistenceStatus
    private static let logger = Logger(subsystem: "com.aryamirsepasi.ResumeCraft", category: "App")

    /// All SwiftData @Model types — shared between schema init and container creation.
    private static let allModelTypes: [any PersistentModel.Type] = [
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
    ]

    @MainActor
    static func makeModelContainer() -> (ModelContainer, PersistenceStatus) {
      // Push the SwiftData schema to CloudKit (DEBUG only).
      initializeCloudKitSchemaIfNeeded()

      let schema = Schema(allModelTypes)

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

    /// Pushes the SwiftData schema to the CloudKit development environment.
    /// Must run at least once per schema change during development. After that,
    /// deploy the schema to production via CloudKit Console before shipping.
    ///
    /// Uses the SAME store URL that SwiftData will use (per Apple's documentation)
    /// and unloads the store before SwiftData creates its ModelContainer.
    /// Guarded by a UserDefaults flag so it only runs once per schema version.
    @MainActor
    private static func initializeCloudKitSchemaIfNeeded() {
        #if DEBUG
        let schemaVersion = "v1" // Bump this when you change the model schema.
        let key = "CloudKitSchemaInitialized_\(schemaVersion)"
        guard !UserDefaults.standard.bool(forKey: key) else {
            logger.info("CloudKit schema already initialized for \(schemaVersion, privacy: .public); skipping.")
            return
        }

        let schema = Schema(allModelTypes)
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(CloudKitConfiguration.containerIdentifier)
        )

        do {
            try autoreleasepool {
                guard let mom = NSManagedObjectModel.makeManagedObjectModel(for: allModelTypes) else {
                    logger.error("Failed to create NSManagedObjectModel; skipping CloudKit schema initialization.")
                    return
                }

                let desc = NSPersistentStoreDescription(url: config.url)
                let ckOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: CloudKitConfiguration.containerIdentifier
                )
                desc.cloudKitContainerOptions = ckOptions
                // Load synchronously so initializeCloudKitSchema() can run
                // before we hand off to SwiftData.
                desc.shouldAddStoreAsynchronously = false

                let container = NSPersistentCloudKitContainer(
                    name: "ResumeCraft",
                    managedObjectModel: mom
                )
                container.persistentStoreDescriptions = [desc]

                var loadError: Error?
                container.loadPersistentStores { _, error in
                    loadError = error
                }
                if let loadError {
                    logger.error("Failed to load CloudKit schema stores: \(loadError.localizedDescription, privacy: .public)")
                    return
                }

                try container.initializeCloudKitSchema(options: [])
                logger.info("Successfully pushed schema to CloudKit development environment.")

                // Remove the store so SwiftData can open it cleanly.
                if let store = container.persistentStoreCoordinator.persistentStores.first {
                    try container.persistentStoreCoordinator.remove(store)
                }
            }

            UserDefaults.standard.set(true, forKey: key)
        } catch {
            // Non-fatal: log and continue. Schema push will retry next launch.
            logger.error("CloudKit schema initialization failed: \(error.localizedDescription, privacy: .public)")
        }
        #endif
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
      let provider = FoundationModelProvider()
      _fmProvider = State(initialValue: provider)
      _aiReviewViewModel = State(initialValue: AIReviewViewModel(ai: provider))

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
      .environment(persistenceStatus)
      .safeAreaInset(edge: .bottom) {
        AppleIntelligenceGate()
      }
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
      let message = String(
        format: String(localized: "ai.gate.message %@"),
        String(describing: reason)
      )
      HStack(spacing: 12) {
        Image(systemName: "sparkles")
        Text(message)
          .frame(maxWidth: .infinity, alignment: .leading)
        Button("ai.gate.openSettings") {
          openAppSettings()
        }
      }
      .font(.footnote)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(.bar)
      .transition(.move(edge: .bottom))
    }
  }
}
