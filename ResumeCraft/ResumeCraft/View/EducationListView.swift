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
            EducationRowView(education: edu) {
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
          onSave: { newEdu in
            if let existing = context.education {
              existing.school = newEdu.school
              existing.degree = newEdu.degree
              existing.field = newEdu.field
              existing.startDate = newEdu.startDate
              existing.endDate = newEdu.endDate
              existing.grade = newEdu.grade
              existing.details = newEdu.details
              existing.isVisible = true
            } else {
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
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 4) {
        Text("\(education.degree) in \(education.field)")
          .font(.headline)
        Text(education.school)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        HStack {
          Text(
            "\(formattedDate(education.startDate)) - \(formattedDate(education.endDate))"
          )
          .font(.caption)
          .foregroundStyle(.tertiary)
          if !education.grade.isEmpty {
            Text("Note: \(education.grade)")
              .font(.caption2)
              .foregroundStyle(.gray)
          }
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(education.degree) in \(education.field) an \(education.school), \(formattedDate(education.startDate)) bis \(formattedDate(education.endDate)), Note: \(education.grade)"
      )
    }
  }

  private func formattedDate(_ date: Date?) -> String {
    guard let date else { return "-" }
    return DateFormatter.resumeMonthYear.string(from: date)
  }
}
