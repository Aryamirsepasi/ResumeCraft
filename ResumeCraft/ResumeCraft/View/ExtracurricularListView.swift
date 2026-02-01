//
//  ExtracurricularListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExtracurricularListView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  @Bindable var model: ExtracurricularModel
  @State private var editorContext: ExtracurricularEditorContext?

  private struct ExtracurricularEditorContext: Identifiable {
    let id = UUID()
    let activity: Extracurricular?
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { activity in
          HStack {
            ExtracurricularRowView(
              activity: activity,
              language: resumeModel.resume.contentLanguage
            ) {
              // Re-fetch fresh instance by id before opening editor
              let id = activity.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editorContext = ExtracurricularEditorContext(activity: fresh)
              } else {
                editorContext = ExtracurricularEditorContext(activity: activity)
              }
            }
            Spacer()
            Toggle(
              isOn: Binding(
                get: { activity.isVisible },
                set: { newValue in
                  activity.isVisible = newValue
                  try? resumeModel.save()
                }
              )
            ) {
              Image(systemName: activity.isVisible ? "eye" : "eye.slash")
                .accessibilityLabel(activity.isVisible ? "Sichtbar" : "Ausgeblendet")
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
      .navigationTitle("Aktivitäten")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editorContext = ExtracurricularEditorContext(activity: nil)
          } label: {
            Label("Hinzufügen", systemImage: "plus")
          }
          .accessibilityLabel("Neue Aktivität hinzufügen")
        }
      }
      .sheet(item: $editorContext) { context in
        ExtracurricularEditorView(
          activity: context.activity,
          onSave: { newActivity, language in
            if let existing = context.activity {
              existing.setTitle(newActivity.title, for: language)
              existing.setOrganization(newActivity.organization, for: language)
              existing.setDetails(newActivity.details, for: language)
              existing.isVisible = true
            } else {
              if language == .english {
                newActivity.title_en = newActivity.title
                newActivity.organization_en = newActivity.organization
                newActivity.details_en = newActivity.details
                newActivity.title = ""
                newActivity.organization = ""
                newActivity.details = ""
              }
              model.add(newActivity)
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

struct ExtracurricularRowView: View {
  let activity: Extracurricular
  let language: ResumeLanguage
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      let fallback = language.fallback
      let title = activity.title(for: language, fallback: fallback)
      let organization = activity.organization(for: language, fallback: fallback)
      let details = activity.details(for: language, fallback: fallback)
      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)
          .accessibilityAddTraits(.isHeader)
        Text(organization)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(details)
          .font(.body)
          .lineLimit(2)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(title) \(String(localized: "resume.label.at", locale: language.locale)) \(organization), \(details)"
      )
      .accessibilityHint("Tippen, um diese Aktivität zu bearbeiten")
    }
  }
}
