//
//  ProjectsListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ProjectsListView: View {
    @Bindable var model: ProjectsModel
    var resumeModel: ResumeEditorModel
    @State private var editingProject: Project?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { project in
                    Button {
                        editingProject = project
                        showEditor = true
                    } label: {
                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(.headline)
                            if !project.technologies.isEmpty {
                                    Text(project.technologies)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let link = project.link, !link.isEmpty {
                                    Text(link)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(project.name), \(project.technologies), \(project.link ?? "")")
                    }
                }
                .onDelete { indices in
                    model.remove(at: indices)
                    try? resumeModel.save()
                }
            }
            .navigationTitle("Projects")
            .toolbar {
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
                        if let existing = editingProject, let idx = model.items.firstIndex(where: { $0.id == existing.id }) {
                            model.items[idx] = newProj
                        } else {
                            model.add(newProj)
                        }
                        showEditor = false
                        try? resumeModel.save()
                    },
                    onCancel: {
                        showEditor = false
                    }
                )
            }
        }
    }
}
