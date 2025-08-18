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
  @State private var editingProject: Project?
  @State private var showEditor = false

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { project in
          HStack {
            ProjectRowView(project: project) {
              // Re-fetch fresh instance by id before opening editor
              let id = project.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editingProject = fresh
              } else {
                editingProject = project
              }
              showEditor = true
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
                .accessibilityLabel(project.isVisible ? "Visible" : "Hidden")
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
      .navigationTitle("Projects")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editingProject = nil
            showEditor = true
          } label: {
            Label("Add", systemImage: "plus")
          }
          .accessibilityLabel("Add new project")
        }
      }
      .sheet(isPresented: $showEditor) {
        ProjectEditorView(
          project: editingProject,
          onSave: { newProj in
            if let existing = editingProject {
              existing.name = newProj.name
              existing.name_de = newProj.name_de
              existing.details = newProj.details
              existing.details_de = newProj.details_de
              existing.technologies = newProj.technologies
              existing.technologies_de = newProj.technologies_de
              existing.link = newProj.link
              existing.isVisible = true
            } else {
              model.add(newProj)
            }
            showEditor = false
            try? resumeModel.save()
          },
          onCancel: { showEditor = false }
        )
      }
    }
  }
}

struct ProjectRowView: View {
  let project: Project
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading) {
        Text(project.name).font(.headline)
        if !project.technologies.isEmpty {
          Text(project.technologies)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        if let link = project.link, !link.isEmpty {
          Text(link).font(.caption2).foregroundStyle(.blue)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(project.name), \(project.technologies), \(project.link ?? "")"
      )
    }
  }
}
