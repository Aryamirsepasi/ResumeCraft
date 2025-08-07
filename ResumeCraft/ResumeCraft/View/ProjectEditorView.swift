//
//  Untitled.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ProjectEditorView: View {
    @State private var name: String = ""
    @State private var name_de: String = ""
    @State private var details: String = ""
    @State private var details_de: String = ""
    @State private var technologies: String = ""
    @State private var technologies_de: String = ""
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

                // MARK: - German Translation Section
                Section("German Translation") {
                    TextField("Name (German)", text: $name_de)
                    TextField("Technologies (German)", text: $technologies_de)
                    TextEditor(text: $details_de)
                        .frame(height: 100)
                        .accessibilityLabel("Project Description (German)")
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
                        // Assign translations
                        proj.name_de = name_de.isEmpty ? nil : name_de
                        proj.details_de = details_de.isEmpty ? nil : details_de
                        proj.technologies_de = technologies_de.isEmpty ? nil : technologies_de

                        onSave(proj)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let p = initialProject {
                    name = p.name
                    name_de = p.name_de ?? ""
                    details = p.details
                    details_de = p.details_de ?? ""
                    technologies = p.technologies
                    technologies_de = p.technologies_de ?? ""
                    link = p.link ?? ""
                }
            }
        }
    }
}
