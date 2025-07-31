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
    @State private var editingEducation: Education?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { edu in
                    HStack {
                        EducationRowView(education: edu) {
                            // Re-fetch fresh instance by id before opening editor
                            let id = edu.id
                            if let fresh = model.items.first(where: { $0.id == id }) {
                                editingEducation = fresh
                            } else {
                                editingEducation = edu
                            }
                            showEditor = true
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
                                .accessibilityLabel(edu.isVisible ? "Visible" : "Hidden")
                        }
                        .labelsHidden()
                        .toggleStyle(.button)
                    }
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
            .navigationTitle("Education")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingEducation = nil
                        showEditor = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityLabel("Add new education")
                }
            }
            .sheet(isPresented: $showEditor) {
                EducationEditorView(
                    education: editingEducation,
                    onSave: { newEdu in
                        if let existing = editingEducation {
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
                        showEditor = false
                        try? resumeModel.save()
                    },
                    onCancel: { showEditor = false }
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
                        Text("Grade: \(education.grade)")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(education.degree) in \(education.field) at \(education.school), \(formattedDate(education.startDate)) to \(formattedDate(education.endDate)), Grade: \(education.grade)"
            )
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return DateFormatter.resumeMonthYear.string(from: date)
    }
}
