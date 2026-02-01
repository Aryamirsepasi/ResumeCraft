//
//  ProjectsListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ProjectsListView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  @Bindable var model: ProjectsModel
  @State private var editorContext: ProjectEditorContext?

  private struct ProjectEditorContext: Identifiable {
    let id = UUID()
    let project: Project?
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { project in
          HStack {
            ProjectRowView(
              project: project,
              language: resumeModel.resume.contentLanguage
            ) {
              // Re-fetch fresh instance by id before opening editor
              let id = project.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editorContext = ProjectEditorContext(project: fresh)
              } else {
                editorContext = ProjectEditorContext(project: project)
              }
            }
            Spacer()
            Toggle(
              isOn: Binding(
                get: { project.isVisible },
                set: { newValue in
                  project.isVisible = newValue
                  try? resumeModel.save()
                }
              )
            ) {
              Image(systemName: project.isVisible ? "eye" : "eye.slash")
                .accessibilityLabel(project.isVisible ? "Sichtbar" : "Ausgeblendet")
            }
            .labelsHidden()
            .toggleStyle(.button)
          }
        }
        .onMove { indices, newOffset in
          model.move(from: indices, to: newOffset)
          try? resumeModel.save()
        }
        .onDelete { indices in
          model.remove(at: indices)
          do {
            try resumeModel.save()
          } catch {
            print("Error saving: \(error.localizedDescription)")
          }
        }
      }
      .navigationTitle("Projekte")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editorContext = ProjectEditorContext(project: nil)
          } label: {
            Label("Hinzufügen", systemImage: "plus")
          }
          .accessibilityLabel("Neues Projekt hinzufügen")
        }
      }
      .sheet(item: $editorContext) { context in
        ProjectEditorView(
          project: context.project,
          onSave: { newProj, language in
            if let existing = context.project {
              existing.setName(newProj.name, for: language)
              existing.setDetails(newProj.details, for: language)
              existing.setTechnologies(newProj.technologies, for: language)
              existing.link = newProj.link
              existing.isVisible = true
            } else {
              if language == .english {
                newProj.name_en = newProj.name
                newProj.details_en = newProj.details
                newProj.technologies_en = newProj.technologies
                newProj.name = ""
                newProj.details = ""
                newProj.technologies = ""
              }
              model.add(newProj)
            }
            editorContext = nil
            try? resumeModel.save()
          },
          onCancel: { editorContext = nil }
        )
      }
    }
  }
}

struct ProjectRowView: View {
  let project: Project
  let language: ResumeLanguage
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      let fallback = language.fallback
      let name = project.name(for: language, fallback: fallback)
      let technologies = project.technologies(for: language, fallback: fallback)
      VStack(alignment: .leading) {
        Text(name).font(.headline)
        if !technologies.isEmpty {
          Text(technologies)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        if let link = project.link, !link.isEmpty {
          Text(link).font(.caption2).foregroundStyle(.blue)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(name), \(technologies), \(project.link ?? "")"
      )
    }
  }
}
