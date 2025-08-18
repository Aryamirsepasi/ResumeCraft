//
//  ExtracurricularEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExtracurricularEditorView: View {
  @State private var title: String
  @State private var title_de: String
  @State private var organization: String
  @State private var organization_de: String
  @State private var details: String
  @State private var details_de: String

  var onSave: (Extracurricular) -> Void
  var onCancel: () -> Void

  init(
    activity: Extracurricular?,
    onSave: @escaping (Extracurricular) -> Void,
    onCancel: @escaping () -> Void
  ) {
    _title = State(initialValue: activity?.title ?? "")
    _title_de = State(initialValue: activity?.title_de ?? "")
    _organization = State(initialValue: activity?.organization ?? "")
    _organization_de = State(initialValue: activity?.organization_de ?? "")
    _details = State(initialValue: activity?.details ?? "")
    _details_de = State(initialValue: activity?.details_de ?? "")
    self.onSave = onSave
    self.onCancel = onCancel
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Activity") {
          TextField("Title", text: $title)
          TextField("Organization", text: $organization)
        }
        Section("Description") {
          TextEditor(text: $details)
            .frame(height: 100)
            .accessibilityLabel("Activity Description")
        }
        Section("German Translation") {
          TextField("Title (German)", text: $title_de)
          TextField("Organization (German)", text: $organization_de)
          TextEditor(text: $details_de)
            .frame(height: 100)
            .accessibilityLabel("Activity Description (German)")
        }
      }
      .navigationTitle("Edit Activity")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let activity = Extracurricular(
              title: title,
              organization: organization,
              details: details
            )
            activity.title_de = title_de.isEmpty ? nil : title_de
            activity.organization_de =
              organization_de.isEmpty ? nil : organization_de
            activity.details_de = details_de.isEmpty ? nil : details_de
            onSave(activity)
          }
          .disabled(title.isEmpty || organization.isEmpty)
        }
      }
    }
  }
}
