//
//  ExtracurricularEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExtracurricularEditorView: View {
    @State private var title: String
    @State private var organization: String
    @State private var description: String

    var onSave: (Extracurricular) -> Void
    var onCancel: () -> Void

    init(
        activity: Extracurricular?,
        onSave: @escaping (Extracurricular) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _title = State(initialValue: activity?.title ?? "")
        _organization = State(initialValue: activity?.organization ?? "")
        _description = State(initialValue: activity?.dscription ?? "")
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
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .accessibilityLabel("Activity Description")
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
                            description: description
                        )
                        onSave(activity)
                    }
                    .disabled(title.isEmpty || organization.isEmpty)
                }
            }
        }
    }
}
