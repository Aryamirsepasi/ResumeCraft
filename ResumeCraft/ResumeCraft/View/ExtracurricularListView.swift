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
            ExtracurricularRowView(activity: activity) {
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
          onSave: { newActivity in
            if let existing = context.activity {
              existing.title = newActivity.title
              existing.organization = newActivity.organization
              existing.details = newActivity.details
              existing.isVisible = true
            } else {
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
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading) {
        Text(activity.title)
          .font(.headline)
          .accessibilityAddTraits(.isHeader)
        Text(activity.organization)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(activity.details)
          .font(.body)
          .lineLimit(2)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(activity.title) bei \(activity.organization), \(activity.details)"
      )
      .accessibilityHint("Tippen, um diese Aktivität zu bearbeiten")
    }
  }
}
