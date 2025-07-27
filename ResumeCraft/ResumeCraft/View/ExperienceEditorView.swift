//
//  ExperienceEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExperienceEditorView: View {
    @State private var title: String
    @State private var company: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isCurrent: Bool
    @State private var details: String

    var onSave: (WorkExperience) -> Void
    var onCancel: () -> Void

    init(
        experience: WorkExperience?,
        onSave: @escaping (WorkExperience) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _title = State(initialValue: experience?.title ?? "")
        _company = State(initialValue: experience?.company ?? "")
        _location = State(initialValue: experience?.location ?? "")
        _startDate = State(initialValue: experience?.startDate ?? Date())
        _endDate = State(initialValue: experience?.endDate ?? Date())
        _isCurrent = State(initialValue: experience?.isCurrent ?? false)
        _details = State(initialValue: experience?.details ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    TextField("Title", text: $title)
                        .autocapitalization(.words)
                    TextField("Company", text: $company)
                    TextField("Location", text: $location)
                }
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Current Position", isOn: $isCurrent)
                    if !isCurrent {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                Section("Description") {
                    TextEditor(text: $details)
                        .frame(height: 100)
                        .accessibilityLabel("Details")
                }
            }
            .navigationTitle("Edit Experience")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let exp = WorkExperience(
                            title: title,
                            company: company,
                            location: location,
                            startDate: startDate,
                            endDate: isCurrent ? nil : endDate,
                            isCurrent: isCurrent,
                            details: details
                        )
                        onSave(exp)
                    }
                    .disabled(title.isEmpty || company.isEmpty)
                }
            }
        }
    }
}
