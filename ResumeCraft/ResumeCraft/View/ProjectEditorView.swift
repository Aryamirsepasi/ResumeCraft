//
//  Untitled.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ProjectEditorView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var technologies: String = ""
    @State private var link: String = ""
    @State private var selectedLanguage: ResumeLanguage = .defaultContent

    var onSave: (Project, ResumeLanguage) -> Void
    var onCancel: () -> Void

    private let initialProject: Project?

    init(
        project: Project?,
        onSave: @escaping (Project, ResumeLanguage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialProject = project
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sprache") {
                    ResumeLanguagePicker(
                        titleKey: "Bearbeitungssprache",
                        selection: $selectedLanguage
                    )
                }
                Section("Projekt") {
                    TextField("Name", text: $name)
                    TextField("Technologien", text: $technologies)
                }

                Section("Beschreibung") {
                    TextEditor(text: $details)
                        .frame(height: 100)
                        .accessibilityLabel("Projektbeschreibung")
                }

                Section("Link") {
                    TextField("URL", text: $link)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
            }
            .navigationTitle("Projekt bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let proj = Project(
                            name: name,
                            details: details,
                            technologies: technologies,
                            link: link.isEmpty ? nil : link
                        )
                        onSave(proj, selectedLanguage)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                selectedLanguage = resumeModel.resume.contentLanguage
                if let p = initialProject {
                    link = p.link ?? ""
                }
                loadFields(for: selectedLanguage)
            }
            .onChange(of: selectedLanguage) { _, newValue in
                resumeModel.resume.contentLanguage = newValue
                try? resumeModel.save()
                loadFields(for: newValue)
            }
        }
    }

    private func loadFields(for language: ResumeLanguage) {
        guard let p = initialProject else {
            name = ""
            details = ""
            technologies = ""
            return
        }
        let fallback: ResumeLanguage? = nil
        name = p.name(for: language, fallback: fallback)
        details = p.details(for: language, fallback: fallback)
        technologies = p.technologies(for: language, fallback: fallback)
    }
}
