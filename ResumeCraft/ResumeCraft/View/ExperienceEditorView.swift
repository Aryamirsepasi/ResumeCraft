//
//  ExperienceEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//
import SwiftUI

struct ExperienceEditorView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel

    @State private var title: String = ""
    @State private var company: String = ""
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isCurrent: Bool = false
    @State private var details: String = ""
    @State private var selectedLanguage: ResumeLanguage = .defaultContent

    var onSave: (WorkExperience, ResumeLanguage) -> Void
    var onCancel: () -> Void

    private let initialExperience: WorkExperience?

    init(
        experience: WorkExperience?,
        onSave: @escaping (WorkExperience, ResumeLanguage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialExperience = experience
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
                Section("Position") {
                    TextField("Titel", text: $title)
                        .autocapitalization(.words)
                    TextField("Unternehmen", text: $company)
                    TextField("Ort", text: $location)
                }

                Section("Zeitraum") {
                    DatePicker("Startdatum", selection: $startDate, displayedComponents: .date)
                    Toggle("Aktuelle Position", isOn: $isCurrent)
                    if !isCurrent {
                        DatePicker("Enddatum", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section("Beschreibung") {
                    TextEditor(text: $details)
                        .frame(height: 100)
                        .accessibilityLabel("Details")
                }
            }
            .navigationTitle("Berufserfahrung bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let exp = WorkExperience(
                            title: title,
                            company: company,
                            location: location,
                            startDate: startDate,
                            endDate: isCurrent ? nil : endDate,
                            isCurrent: isCurrent,
                            details: details
                        )
                        onSave(exp, selectedLanguage)
                    }
                    .disabled(title.isEmpty || company.isEmpty)
                }
            }
            .onAppear {
                selectedLanguage = resumeModel.resume.contentLanguage
                if let e = initialExperience {
                    startDate = e.startDate
                    endDate = e.endDate ?? e.startDate
                    isCurrent = e.isCurrent
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
        guard let e = initialExperience else {
            title = ""
            company = ""
            location = ""
            details = ""
            return
        }
        let fallback: ResumeLanguage? = nil
        title = e.title(for: language, fallback: fallback)
        company = e.company(for: language, fallback: fallback)
        location = e.location(for: language, fallback: fallback)
        details = e.details(for: language, fallback: fallback)
    }
}
