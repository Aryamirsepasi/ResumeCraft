//
//  EducationEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct EducationEditorView: View {
  @State private var school: String = ""
  @State private var school_de: String = ""
  @State private var degree: String = ""
  @State private var degree_de: String = ""
  @State private var field: String = ""
  @State private var field_de: String = ""
  @State private var startDate: Date = Date()
  @State private var endDate: Date = Date()
  @State private var grade: String = ""
  @State private var details: String = ""
  @State private var details_de: String = ""

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
        Section("School") {
          TextField("School", text: $school)
            .autocapitalization(.words)
          TextField("Degree", text: $degree)
          TextField("Field of Study", text: $field)
        }
        Section("Dates") {
          DatePicker(
            "Start Date",
            selection: $startDate,
            displayedComponents: .date
          )
          DatePicker(
            "End Date",
            selection: $endDate,
            in: startDate...,
            displayedComponents: .date
          )
        }
        Section("Details") {
          TextField("Grade", text: $grade)
          TextEditor(text: $details)
            .frame(height: 80)
            .accessibilityLabel("Description")
        }

        Section("German Translation") {
          TextField("School (German)", text: $school_de)
          TextField("Degree (German)", text: $degree_de)
          TextField("Field of Study (German)", text: $field_de)
          TextEditor(text: $details_de)
            .frame(height: 80)
            .accessibilityLabel("Description (German)")
        }
      }
      .navigationTitle("Edit Education")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let edu = Education(
              school: school,
              degree: degree,
              field: field,
              startDate: startDate,
              endDate: endDate,
              grade: grade,
              details: details
            )
            edu.school_de = school_de.isEmpty ? nil : school_de
            edu.degree_de = degree_de.isEmpty ? nil : degree_de
            edu.field_de = field_de.isEmpty ? nil : field_de
            edu.details_de = details_de.isEmpty ? nil : details_de
            onSave(edu)
          }
          .disabled(school.isEmpty || degree.isEmpty)
        }
      }
      .onAppear {
        guard let e = initialEducation else { return }
        school = e.school
        school_de = e.school_de ?? ""
        degree = e.degree
        degree_de = e.degree_de ?? ""
        field = e.field
        field_de = e.field_de ?? ""
        startDate = e.startDate
        endDate = e.endDate ?? e.startDate
        grade = e.grade
        details = e.details
        details_de = e.details_de ?? ""
      }
    }
  }
}
