//
//  HomeView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 06.08.25.
//

import SwiftUI

struct HomeView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  let openPreview: () -> Void
  let importPDF: () -> Void
  let openSettings: () -> Void

  var body: some View {
    NavigationStack {
      List {
          
          Section {

              Button(action: { importPDF() }) {
                Label("Import from PDF", systemImage: "doc.richtext")
              }
            .accessibilityHint("Import your resume as a PDF and auto-fill sections.")
          }
          
        Section {
          HomeRow(
            title: Text("Personal Info"),
            subtitle: Text("Name, contact, links"),
            systemImage: "person",
            destination: AnyView(PersonalInfoView(model: resumeModel.personalModel))
          )
            HomeRow(
              title: Text("Summary"),
              subtitle: Text("Short intro below personal info"),
              systemImage: "text.justify",
              destination: AnyView(SummaryEditorView())
            )
          HomeRow(
            title: Text("Skills"),
            subtitle: Text("Technical and soft skills"),
            systemImage: "list.bullet",
            destination: AnyView(SkillsListView(model: resumeModel.skillsModel))
          )
          HomeRow(
            title: Text("Work Experience"),
            subtitle: Text("Jobs and responsibilities"),
            systemImage: "briefcase",
            destination: AnyView(ExperienceListView(model: resumeModel.experienceModel))
          )
          HomeRow(
            title: Text("Projects"),
            subtitle: Text("Personal and professional projects"),
            systemImage: "hammer.fill",
            destination: AnyView(ProjectsListView(model: resumeModel.projectsModel))
          )
          HomeRow(
            title: Text("Education"),
            subtitle: Text("Degrees, dates, details"),
            systemImage: "graduationcap",
            destination: AnyView(EducationListView(model: resumeModel.educationModel))
          )
          HomeRow(
            title: Text("Activities"),
            subtitle: Text("Clubs, volunteering, more"),
            systemImage: "star.fill",
            destination: AnyView(ExtracurricularListView(model: resumeModel.extracurricularModel))
          )
          HomeRow(
            title: Text("Languages"),
            subtitle: Text("Languages and proficiency"),
            systemImage: "globe",
            destination: AnyView(LanguagesListView(model: resumeModel.languageModel))
          )
        }
      }
      .listSectionSpacing(10)
      .navigationTitle("ResumeCraft")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: openPreview) {
            Label("Preview", systemImage: "doc.text.magnifyingglass")
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: openSettings) {
            Label("Settings", systemImage: "gearshape")
          }
        }
      }
    }
  }
}

private struct HomeRow: View {
  let title: Text
  let subtitle: Text
  let systemImage: String
  let destination: AnyView

  var body: some View {
    NavigationLink {
      destination
    } label: {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(Color.accentColor)
          .frame(width: 28)
        VStack(alignment: .leading, spacing: 2) {
          title.font(.headline)
          subtitle.font(.caption).foregroundStyle(.secondary)
        }
      }
      .padding(.vertical, 6)
    }
  }
}
