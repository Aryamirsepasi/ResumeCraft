//
//  EducationEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct EducationEditorView: View {
    @State private var school: String
    @State private var degree: String
    @State private var field: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var grade: String
    @State private var details: String

    var onSave: (Education) -> Void
    var onCancel: () -> Void

    init(
        education: Education?,
        onSave: @escaping (Education) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _school = State(initialValue: education?.school ?? "")
        _degree = State(initialValue: education?.degree ?? "")
        _field = State(initialValue: education?.field ?? "")
        _startDate = State(initialValue: education?.startDate ?? Date())
        _endDate = State(initialValue: education?.endDate ?? Date())
        _grade = State(initialValue: education?.grade ?? "")
        _details = State(initialValue: education?.details ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
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
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                Section("Details") {
                    TextField("Grade", text: $grade)
                    TextEditor(text: $details)
                        .frame(height: 80)
                        .accessibilityLabel("Description")
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
                        onSave(edu)
                    }
                    .disabled(school.isEmpty || degree.isEmpty)
                }
            }
        }
    }
}
