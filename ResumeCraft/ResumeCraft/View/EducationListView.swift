//
//  EducationListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct EducationListView: View {
    @Bindable var model: EducationModel
    var resumeModel: ResumeEditorModel
    @State private var editingEducation: Education?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { edu in
                    Button {
                        editingEducation = edu
                        showEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(edu.degree) in \(edu.field)")
                                .font(.headline)
                            Text(edu.school)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("\(formattedDate(edu.startDate)) - \(formattedDate(edu.endDate))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                if !edu.grade.isEmpty {
                                    Text("Grade: \(edu.grade)")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(edu.degree) in \(edu.field) at \(edu.school), \(formattedDate(edu.startDate)) to \(formattedDate(edu.endDate)), Grade: \(edu.grade)")
                    }
                }
                .onDelete { indices in
                    model.remove(at: indices)
                    try? resumeModel.save()
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
                        if let existing = editingEducation, let idx = model.items.firstIndex(where: { $0.id == existing.id }) {
                            model.items[idx] = newEdu
                        } else {
                            model.add(newEdu)
                        }
                        showEditor = false
                        try? resumeModel.save()
                    },
                    onCancel: {
                        showEditor = false
                    }
                )
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        return fmt.string(from: date)
    }
}
