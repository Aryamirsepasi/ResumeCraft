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
  @State private var isICloudAvailable = false

  @State private var openRouterSettings = OpenRouterSettings()
  @State private var openRouterProvider =
    OpenRouterProvider(config: OpenRouterSettings().config)

    // NEW: local on-device AI provider
    @State private var fmProvider = FoundationModelProvider()
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
    //let settings = OpenRouterSettings()
    //let provider = OpenRouterProvider(config: settings.config)
    //_openRouterSettings = State(initialValue: settings)
    //_openRouterProvider = State(initialValue: provider)
    //_aiReviewViewModel = State(initialValue: AIReviewViewModel(ai: provider))
      let provider = FoundationModelProvider()
          _fmProvider = State(initialValue: provider)
          _aiReviewViewModel = State(initialValue: AIReviewViewModel(ai: provider)) // still conforms to AIProvider
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
      .environment(fmProvider)
      .environment(aiReviewViewModel)
      .environment(openRouterSettings)
      .environment(openRouterProvider)
      .task {
        //openRouterProvider.updateConfig(openRouterSettings.config)
        await checkICloudAvailability()
      }
      .overlay(AppleIntelligenceGate())
    }
    .modelContainer(Self.container)
  }

  @MainActor
  private func checkICloudAvailability() async {
    let status = try? await CKContainer.default().accountStatus()
    isICloudAvailable = (status == .available)
  }
}

// Small helper: shows a subtle banner if Apple Intelligence is unavailable.
@MainActor
private struct AppleIntelligenceGate: View {
  var body: some View {
    let availability = SystemLanguageModel.default.availability
    if case .unavailable(let reason) = availability {
      VStack {
        Spacer()
        HStack(spacing: 12) {
          Image(systemName: "sparkles")
          Text("On-device AI is unavailable (\(String(describing: reason))). Enable Apple Intelligence in Settings.")
          Button("Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
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
