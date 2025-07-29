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

            OnboardingModelManagementPage(
                finishAction: { hasSeenOnboarding = true }
            )
            .tag(2)
        }
        .tabViewStyle(.page)
        .animation(.easeInOut, value: page)
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .background(
            Group {
                /*if #available(iOS 18.0, *) {
                    Color.clear.liquidGlassBackground()
                } else {*/
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                        startPoint: .top, endPoint: .bottom
                    )
                //}
            }
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

            Text("Build a job-ready résumé with privacy-first on-device AI.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()
            Button("Continue", action: nextAction)
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .buttonBorderShape(.capsule)
                .padding(.bottom, 24)
        }
        .padding()
        .background(
            Group {
                /*if #available(iOS 18.0, *) {
                    Color.clear.glassBackgroundEffect()
                }*/
            }
        )
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
                FeatureBullet(text: "🤖 Get on-device AI feedback, no internet needed")
                FeatureBullet(text: "📝 Export ATS-optimized résumés as PDF")
                FeatureBullet(text: "🔒 100% privacy – your data stays on your device")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )

            Spacer()
            Button("Next", action: nextAction)
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .buttonBorderShape(.capsule)
                .padding(.bottom, 24)
        }
        .padding()
        .background(
            Group {
                /*if #available(iOS 18.0, *) {
                    Color.clear.glassBackgroundEffect()
                }*/
            }
        )
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

struct OnboardingModelManagementPage: View {
    var finishAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Download Your AI Model")
                .font(.title2).fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("ResumeCraft runs offline. Download a language model to unlock smart feedback and résumé analysis. You can skip this step and download later in Settings.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ModelManagementView()
                .frame(maxHeight: 350)

            Spacer()
            Button("Get Started") {
                finishAction()
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)
            .buttonBorderShape(.capsule)
            .padding(.bottom, 24)
        }
        .padding()
        .background(
            Group {
                /*if #available(iOS 18.0, *) {
                    Color.clear.glassEffect()
                }*/
            }
        )
    }
}
