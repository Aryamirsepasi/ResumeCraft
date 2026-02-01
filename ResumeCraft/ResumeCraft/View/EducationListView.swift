//
//  EducationListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct EducationListView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  @Bindable var model: EducationModel
  @State private var editorContext: EducationEditorContext?

  private struct EducationEditorContext: Identifiable {
    let id = UUID()
    let education: Education?
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { edu in
          HStack {
            EducationRowView(
              education: edu,
              language: resumeModel.resume.contentLanguage
            ) {
              // Re-fetch fresh instance by id before opening editor
              let id = edu.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editorContext = EducationEditorContext(education: fresh)
              } else {
                editorContext = EducationEditorContext(education: edu)
              }
            }
            Spacer()
            Toggle(
              isOn: Binding(
                get: { edu.isVisible },
                set: { newValue in
                  edu.isVisible = newValue
                  try? resumeModel.save()
                }
              )
            ) {
              Image(systemName: edu.isVisible ? "eye" : "eye.slash")
                .accessibilityLabel(edu.isVisible ? "Sichtbar" : "Ausgeblendet")
            }
            .labelsHidden()
            .toggleStyle(.button)
          }
        }
        .onMove { indices, newOffset in
          model.move(from: indices, to: newOffset)
          try? resumeModel.save()
        }
        .onDelete { indices in
          model.remove(at: indices)
          do {
            try resumeModel.save()
          } catch {
            print("Error saving: \(error.localizedDescription)")
          }
        }
      }
      .navigationTitle("Ausbildung")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editorContext = EducationEditorContext(education: nil)
          } label: {
            Label("Hinzufügen", systemImage: "plus")
          }
          .accessibilityLabel("Neue Ausbildung hinzufügen")
        }
      }
      .sheet(item: $editorContext) { context in
        EducationEditorView(
          education: context.education,
          onSave: { newEdu, language in
            if let existing = context.education {
              existing.setSchool(newEdu.school, for: language)
              existing.setDegree(newEdu.degree, for: language)
              existing.setField(newEdu.field, for: language)
              existing.startDate = newEdu.startDate
              existing.endDate = newEdu.endDate
              existing.setGrade(newEdu.grade, for: language)
              existing.setDetails(newEdu.details, for: language)
              existing.isVisible = true
            } else {
              if language == .english {
                newEdu.school_en = newEdu.school
                newEdu.degree_en = newEdu.degree
                newEdu.field_en = newEdu.field
                newEdu.grade_en = newEdu.grade
                newEdu.details_en = newEdu.details
                newEdu.school = ""
                newEdu.degree = ""
                newEdu.field = ""
                newEdu.grade = ""
                newEdu.details = ""
              }
              model.add(newEdu)
            }
            editorContext = nil
            try? resumeModel.save()
          },
          onCancel: { editorContext = nil }
        )
      }
    }
  }
}

struct EducationRowView: View {
  let education: Education
  let language: ResumeLanguage
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      let fallback = language.fallback
      let degree = education.degree(for: language, fallback: fallback)
      let field = education.field(for: language, fallback: fallback)
      let school = education.school(for: language, fallback: fallback)
      let grade = education.grade(for: language, fallback: fallback)
      let gradeLabel = String(localized: "resume.label.grade", locale: language.locale)
      let titleLine = field.isEmpty ? degree : "\(degree) in \(field)"
      VStack(alignment: .leading, spacing: 4) {
        Text(titleLine)
          .font(.headline)
        Text(school)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        HStack {
          Text(
            "\(formattedDate(education.startDate)) - \(formattedDate(education.endDate))"
          )
          .font(.caption)
          .foregroundStyle(.tertiary)
          if !grade.isEmpty {
            Text("\(gradeLabel): \(grade)")
              .font(.caption2)
              .foregroundStyle(.gray)
          }
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(titleLine) an \(school), \(formattedDate(education.startDate)) bis \(formattedDate(education.endDate)), \(gradeLabel): \(grade)"
      )
    }
  }

  private func formattedDate(_ date: Date?) -> String {
    guard let date else { return "-" }
    return DateFormatter.resumeMonthYear(for: language).string(from: date)
  }
}
