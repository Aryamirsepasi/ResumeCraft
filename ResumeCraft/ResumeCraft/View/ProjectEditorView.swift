//
//  Untitled.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ProjectEditorView: View {
    @State private var name: String
    @State private var description: String
    @State private var technologies: String
    @State private var link: String

    var onSave: (Project) -> Void
    var onCancel: () -> Void

    init(
        project: Project?,
        onSave: @escaping (Project) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _name = State(initialValue: project?.name ?? "")
        _description = State(initialValue: project?.dscription ?? "")
        _technologies = State(initialValue: project?.technologies ?? "")
        _link = State(initialValue: project?.link ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                    TextField("Technologies", text: $technologies)
                }
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .accessibilityLabel("Project Description")
                }
                Section("Link") {
                    TextField("URL", text: $link)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
            }
            .navigationTitle("Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let proj = Project(
                            name: name,
                            description: description,
                            technologies: technologies,
                            link: link.isEmpty ? nil : link
                        )
                        onSave(proj)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
