//
//  OnboardingFlow.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 29.07.25.
//

import SwiftUI

struct OnboardingFlow: View {
  @Binding var hasSeenOnboarding: Bool
  @State private var page: Int = 0

  var body: some View {
    TabView(selection: $page) {
      OnboardingWelcomePage {
        withAnimation { page += 1 }
      }
      .tag(0)

      OnboardingFeaturesPage {
        withAnimation { page += 1 }
      }
      .tag(1)

      OnboardingAIChoicePage(
        finishAction: { hasSeenOnboarding = true }
      )
      .tag(2)
    }
    .tabViewStyle(.page)
    .animation(.easeInOut, value: page)
    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
    .background(
      LinearGradient(
        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    )
  }
}

struct OnboardingWelcomePage: View {
  var nextAction: () -> Void

  var body: some View {
    VStack(spacing: 32) {
      Spacer()
      Image("AppIcon")
        .resizable()
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 12)
        .accessibilityHidden(true)

      Text("Welcome to ResumeCraft")
        .font(.largeTitle).fontWeight(.bold)
        .multilineTextAlignment(.center)

      Text("Build a job-ready résumé with privacy-first AI.")
        .font(.title3)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Spacer()
      Button("Continue", action: nextAction)
        .font(.title2)
        .frame(width: 150, height: 40)
        .background(Color.blue)
        .foregroundStyle(Color.white)
        .cornerRadius(30)
        .padding(.bottom, 24)
    }
    .padding()
  }
}

struct OnboardingFeaturesPage: View {
  var nextAction: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      Text("What ResumeCraft Can Do")
        .font(.title).fontWeight(.semibold)

      VStack(alignment: .leading, spacing: 18) {
        FeatureBullet(text: "📄 Parse your existing résumé from PDF")
        FeatureBullet(text: "🤖 Get AI feedback on your résumé")
        FeatureBullet(text: "📝 Export ATS-optimized résumés as PDF")
        FeatureBullet(text: "🔒 Privacy-first design")
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )

      Spacer()
      Button("Next", action: nextAction)
        .font(.title2)
        .frame(width: 150, height: 40)
        .background(Color.blue)
        .foregroundStyle(Color.white)
        .cornerRadius(30)
        .padding(.bottom, 24)
    }
    .padding()
  }
}

struct FeatureBullet: View {
  var text: String
  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundColor(.accentColor)
      Text(text)
        .font(.body)
    }
  }
}

struct OnboardingAIChoicePage: View {
  var finishAction: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      Text("Choose How You Use AI")
        .font(.title2).fontWeight(.semibold)
        .multilineTextAlignment(.center)

      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "cpu")
            .foregroundStyle(.primary)
          VStack(alignment: .leading, spacing: 6) {
            Text("Local (MLX)")
              .font(.headline)
            Text(
              "Runs on your device using downloaded models. 100% offline once installed."
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }

        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "cloud")
            .foregroundStyle(.primary)
          VStack(alignment: .leading, spacing: 6) {
            Text("OpenRouter (Cloud)")
              .font(.headline)
            Text(
              "Uses cloud models via your OpenRouter API key. No local model required."
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }

        Divider().padding(.vertical, 4)

        Text(
          "You can select your preferred AI backend anytime in Settings. For OpenRouter, add your API key and model name. For Local, download a model in Settings."
        )
        .font(.footnote)
        .foregroundColor(.secondary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )

      Spacer()
      Button("Get Started") {
        finishAction()
      }
      .font(.title2)
      .frame(width: 150, height: 40)
      .background(Color.blue)
      .foregroundStyle(Color.white)
      .cornerRadius(30)
      .padding(.bottom, 24)
    }
    .padding()
  }
}
