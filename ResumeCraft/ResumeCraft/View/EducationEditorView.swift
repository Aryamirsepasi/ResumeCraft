//
//  EducationEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct EducationEditorView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel

  @State private var school: String = ""
  @State private var degree: String = ""
  @State private var field: String = ""
  @State private var startDate: Date = Date()
  @State private var endDate: Date = Date()
  @State private var grade: String = ""
  @State private var details: String = ""
  @State private var selectedLanguage: ResumeLanguage = .defaultContent

  var onSave: (Education, ResumeLanguage) -> Void
  var onCancel: () -> Void

  private let initialEducation: Education?

  init(
    education: Education?,
    onSave: @escaping (Education, ResumeLanguage) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.initialEducation = education
    self.onSave = onSave
    self.onCancel = onCancel
    // Defer state population to .onAppear to avoid stale snapshots
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
        Section("Schule") {
          TextField("Schule", text: $school)
            .autocapitalization(.words)
          TextField("Abschluss", text: $degree)
          TextField("Fachrichtung", text: $field)
        }
        Section("Zeitraum") {
          DatePicker(
            "Startdatum",
            selection: $startDate,
            displayedComponents: .date
          )
          DatePicker(
            "Enddatum",
            selection: $endDate,
            in: startDate...,
            displayedComponents: .date
          )
        }
        Section("Details") {
          TextField("Note", text: $grade)
          TextEditor(text: $details)
            .frame(height: 80)
            .accessibilityLabel("Beschreibung")
        }
      }
      .navigationTitle("Ausbildung bearbeiten")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Abbrechen", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Speichern") {
            let edu = Education(
              school: school,
              degree: degree,
              field: field,
              startDate: startDate,
              endDate: endDate,
              grade: grade,
              details: details
            )
            onSave(edu, selectedLanguage)
          }
          .disabled(school.isEmpty || degree.isEmpty)
        }
      }
      .onAppear {
        selectedLanguage = resumeModel.resume.contentLanguage
        if let e = initialEducation {
          startDate = e.startDate
          endDate = e.endDate ?? e.startDate
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
    guard let e = initialEducation else {
      school = ""
      degree = ""
      field = ""
      grade = ""
      details = ""
      return
    }
    let fallback: ResumeLanguage? = nil
    school = e.school(for: language, fallback: fallback)
    degree = e.degree(for: language, fallback: fallback)
    field = e.field(for: language, fallback: fallback)
    grade = e.grade(for: language, fallback: fallback)
    details = e.details(for: language, fallback: fallback)
  }
}
