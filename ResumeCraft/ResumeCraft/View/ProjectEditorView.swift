//
//  Untitled.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ProjectEditorView: View {
    @State private var name: String = ""
    @State private var details: String = ""
    @State private var technologies: String = ""
    @State private var link: String = ""

    var onSave: (Project) -> Void
    var onCancel: () -> Void

    private let initialProject: Project?

    init(
        project: Project?,
        onSave: @escaping (Project) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialProject = project
        self.onSave = onSave
        self.onCancel = onCancel
        // Do not assign @State here; we'll copy in onAppear for freshness
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                    TextField("Technologies", text: $technologies)
                }
                Section("Description") {
                    TextEditor(text: $details)
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
                            details: details,
                            technologies: technologies,
                            link: link.isEmpty ? nil : link
                        )
                        onSave(proj)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                // Populate from the freshest instance
                if let p = initialProject {
                    name = p.name
                    details = p.details
                    technologies = p.technologies
                    link = p.link ?? ""
                }
            }
        }
    }
}
