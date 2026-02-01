//
//  ExtracurricularEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExtracurricularEditorView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel

  @State private var title: String = ""
  @State private var organization: String = ""
  @State private var details: String = ""
  @State private var selectedLanguage: ResumeLanguage = .defaultContent

  var onSave: (Extracurricular, ResumeLanguage) -> Void
  var onCancel: () -> Void
  private let initialActivity: Extracurricular?

  init(
    activity: Extracurricular?,
    onSave: @escaping (Extracurricular, ResumeLanguage) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.initialActivity = activity
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
        Section("Aktivität") {
          TextField("Titel", text: $title)
          TextField("Organisation", text: $organization)
        }
        Section("Beschreibung") {
          TextEditor(text: $details)
            .frame(height: 100)
            .accessibilityLabel("Aktivitätsbeschreibung")
        }
      }
      .navigationTitle("Aktivität bearbeiten")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Abbrechen", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Speichern") {
            let activity = Extracurricular(
              title: title,
              organization: organization,
              details: details
            )
            onSave(activity, selectedLanguage)
          }
          .disabled(title.isEmpty || organization.isEmpty)
        }
      }
      .onAppear {
        selectedLanguage = resumeModel.resume.contentLanguage
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
    guard let activity = initialActivity else {
      title = ""
      organization = ""
      details = ""
      return
    }
    let fallback: ResumeLanguage? = nil
    title = activity.title(for: language, fallback: fallback)
    organization = activity.organization(for: language, fallback: fallback)
    details = activity.details(for: language, fallback: fallback)
  }
}
