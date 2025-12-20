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

      Text("Willkommen bei ResumeCraft")
        .font(.largeTitle).fontWeight(.bold)
        .multilineTextAlignment(.center)

      Text("Erstelle einen jobbereiten Lebenslauf mit datenschutzfreundlicher KI.")
        .font(.title3)
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

      Spacer()
      Button("Weiter", action: nextAction)
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
      Text("Was ResumeCraft kann")
        .font(.title).fontWeight(.semibold)

      VStack(alignment: .leading, spacing: 18) {
        FeatureBullet(text: "Lebenslauf aus PDF importieren und analysieren")
        FeatureBullet(text: "On-Device-KI-Feedback erhalten (Apple Intelligence)")
        FeatureBullet(text: "ATS-freundliche Lebensläufe als PDF exportieren")
        FeatureBullet(text: "Mit iCloud synchronisieren (private Datenbank)")
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )

      Spacer()
      Button("Weiter", action: nextAction)
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
      Text("So funktioniert KI in ResumeCraft")
        .font(.title2).fontWeight(.semibold)
        .multilineTextAlignment(.center)

      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "sparkles")
            .foregroundStyle(.primary)
          VStack(alignment: .leading, spacing: 6) {
            Text("On-Device-KI (Apple Intelligence)")
              .font(.headline)
            Text(
              "Wenn verfügbar, nutzt ResumeCraft das On-Device-Sprachmodell von Apple, um deinen Lebenslauf zu prüfen. Deine Daten bleiben auf deinem Gerät."
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
        }

        Divider().padding(.vertical, 4)

        Text(
          "Wenn On-Device-KI nicht verfügbar ist, kannst du trotzdem bearbeiten, importieren und exportieren. Um die KI-Bewertung zu aktivieren, schalte Apple Intelligence in den Einstellungen ein."
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
      Button("Loslegen") {
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
