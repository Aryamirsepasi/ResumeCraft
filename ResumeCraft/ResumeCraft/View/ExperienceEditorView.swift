//
//  ExperienceEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExperienceEditorView: View {
    @State private var title: String = ""
    @State private var company: String = ""
    @State private var location: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isCurrent: Bool = false
    @State private var details: String = ""

    var onSave: (WorkExperience) -> Void
    var onCancel: () -> Void

    private let initialExperience: WorkExperience?

    init(
        experience: WorkExperience?,
        onSave: @escaping (WorkExperience) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.initialExperience = experience
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
            .onAppear {
                if let e = initialExperience {
                    title = e.title
                    company = e.company
                    location = e.location
                    startDate = e.startDate
                    endDate = e.endDate ?? e.startDate
                    isCurrent = e.isCurrent
                    details = e.details
                }
            }
        }
    }
}
