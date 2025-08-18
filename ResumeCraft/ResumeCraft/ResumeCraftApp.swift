//
//  ResumeCraftApp.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct ResumeCraftApp: App {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
  @State private var isICloudAvailable = false

  @State private var openRouterSettings = OpenRouterSettings()
  @State private var openRouterProvider =
    OpenRouterProvider(config: OpenRouterSettings().config)
  @State private var aiReviewViewModel: AIReviewViewModel

    @MainActor
    static var container: ModelContainer = {
      let schema = Schema([
        Resume.self, PersonalInfo.self, WorkExperience.self, Project.self,
        Skill.self, Education.self, Extracurricular.self, Language.self,
      ])

      let cloud = ModelConfiguration(
        schema: schema,
        cloudKitDatabase: .private("iCloud.com.aryamirsepasi.ResumeCraft")
      )

      do {
        let container = try ModelContainer(
          for: schema,
          configurations: [cloud]
        )
        return container
      } catch {
        // Fail loudly so you actually see misconfigurations
        fatalError(
          "CloudKit ModelContainer failed: \(error.localizedDescription)"
        )
      }
    }()

  init() {
    let settings = OpenRouterSettings()
    let provider = OpenRouterProvider(config: settings.config)
    _openRouterSettings = State(initialValue: settings)
    _openRouterProvider = State(initialValue: provider)
    _aiReviewViewModel = State(initialValue: AIReviewViewModel(ai: provider))
  }

  var body: some Scene {
    WindowGroup {
      Group {
        if !isICloudAvailable {
          VStack(spacing: 20) {
            Text("iCloud Not Available")
              .font(.title2).bold()
            Text("Please sign in to your iCloud account in Settings to use ResumeCraft with full features.")
              .multilineTextAlignment(.center)
              .padding()
            Button("Open iOS Settings") {
              if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
              }
            }
            .buttonStyle(.borderedProminent)
          }
          .padding()
        } else {
          if hasSeenOnboarding {
            ResumeRootView()
          } else {
            OnboardingFlow(hasSeenOnboarding: $hasSeenOnboarding)
          }
        }
      }
      .environment(openRouterSettings)
      .environment(openRouterProvider)
      .environment(aiReviewViewModel)
      .task {
        openRouterProvider.updateConfig(openRouterSettings.config)
        await checkICloudAvailability()
      }
    }
    .modelContainer(Self.container)
  }

  @MainActor
  private func checkICloudAvailability() async {
    let status = try? await CKContainer.default().accountStatus()
    isICloudAvailable = (status == .available)
  }
}
