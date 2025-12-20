//
//  EducationEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct EducationEditorView: View {
  @State private var school: String = ""
  @State private var degree: String = ""
  @State private var field: String = ""
  @State private var startDate: Date = Date()
  @State private var endDate: Date = Date()
  @State private var grade: String = ""
  @State private var details: String = ""

  var onSave: (Education) -> Void
  var onCancel: () -> Void

  private let initialEducation: Education?

  init(
    education: Education?,
    onSave: @escaping (Education) -> Void,
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
            onSave(edu)
          }
          .disabled(school.isEmpty || degree.isEmpty)
        }
      }
      .onAppear {
        guard let e = initialEducation else { return }
        school = e.school
        degree = e.degree
        field = e.field
        startDate = e.startDate
        endDate = e.endDate ?? e.startDate
        grade = e.grade
        details = e.details
      }
    }
  }
}
