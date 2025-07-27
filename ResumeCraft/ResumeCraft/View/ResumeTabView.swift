//
//  ResumeTabView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData

struct ResumeTabView: View {
    @Environment(\.modelContext) private var context
    @State private var resumeModel: ResumeEditorModel?
    @State private var showPreview = false
    @State private var showFeedbackSheet = false
    @State private var showSettings = false

    // Create MLXService and AIReviewViewModel on the main actor
    @MainActor
    private var mlxService = MLXService()
    @MainActor
    private let aiReviewModel: AIReviewViewModel

    init() {
        let service = MLXService()
        self.mlxService = service
        self.aiReviewModel = AIReviewViewModel(mlxService: service)
    }

    private let feedbackSections = [
        "Personal Info", "Work Experience", "Projects", "Extracurricular", "Languages"
    ]

    private func sectionText(for name: String) -> String {
        guard let model = resumeModel else { return "" }
        switch name {
        case "Personal Info":
            let p = model.resume.personal
            return "\(p?.firstName ?? "") \(p?.lastName ?? ""), \(p?.email ?? ""), \(p?.phone ?? ""), \(p?.address ?? "")"
        case "Work Experience":
            return model.resume.experiences.map { "\($0.title), \($0.company): \($0.details)" }.joined(separator: "\n")
        case "Projects":
            return model.resume.projects.map { "\($0.name): \($0.dscription)" }.joined(separator: "\n")
        case "Extracurricular":
            return model.resume.extracurriculars.map { "\($0.title): \($0.dscription)" }.joined(separator: "\n")
        case "Languages":
            return model.resume.languages.map { "\($0.name) (\($0.proficiency))" }.joined(separator: ", ")
        default:
            return ""
        }
    }

    var body: some View {
        Group {
            if let model = resumeModel {
                TabView {
                    PersonalInfoView(model: model.personalModel, resumeModel: model)
                        .tabItem {
                            Label("Personal", systemImage: "person")
                        }
                    ExperienceListView(model: model.experienceModel, resumeModel: model)
                        .tabItem {
                            Label("Experience", systemImage: "briefcase")
                        }
                    ProjectsListView(model: model.projectsModel, resumeModel: model)
                        .tabItem {
                            Label("Projects", systemImage: "hammer.fill")
                        }
                    ExtracurricularListView(model: model.extracurricularModel, resumeModel: model)
                        .tabItem {
                            Label("Activities", systemImage: "star.fill")
                        }
                    LanguagesListView(model: model.languageModel, resumeModel: model)
                        .tabItem {
                            Label("Languages", systemImage: "globe")
                        }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            showPreview = true
                        } label: {
                            Label("Preview", systemImage: "doc.text.magnifyingglass")
                        }
                        Button {
                            showFeedbackSheet = true
                        } label: {
                            Label("Get Feedback", systemImage: "sparkle.magnifyingglass")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .sheet(isPresented: $showPreview) {
                    if let model = resumeModel {
                        ResumePreviewScreen(resume: model.resume)
                    }
                }
                .sheet(isPresented: $showFeedbackSheet) {
                    AIReviewSheet(
                        viewModel: aiReviewModel,
                        sectionOptions: feedbackSections,
                        sectionTextProvider: sectionText
                    )
                }
                .sheet(isPresented: $showSettings) {
                    ModelManagementView()
                }
            } else {
                ProgressView("Loading Resume…")
                    .task {
                        let descriptor = FetchDescriptor<Resume>(sortBy: [SortDescriptor(\.updated, order: .reverse)])
                        if let found = try? context.fetch(descriptor).first {
                            resumeModel = ResumeEditorModel(resume: found, context: context)
                        } else {
                            let newResume = Resume()
                            context.insert(newResume)
                            try? context.save()
                            resumeModel = ResumeEditorModel(resume: newResume, context: context)
                        }
                    }
            }
        }
    }
}
