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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Resume.self, PersonalInfo.self, WorkExperience.self,
            Project.self, Skill.self, Education.self, Extracurricular.self, Language.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ResumeTabView()
                
            } else {
                OnboardingFlow(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
