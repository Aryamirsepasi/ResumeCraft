//
//  ExperienceListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExperienceListView: View {
    @Bindable var model: ExperienceModel
    var resumeModel: ResumeEditorModel
    @State private var editingExperience: WorkExperience?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { exp in
                    Button {
                        editingExperience = exp
                        showEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(exp.title), \(exp.company)")
                                .font(.headline)
                            HStack {
                                Text(exp.location)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(formattedDate(exp.startDate)) - \(exp.isCurrent ? "Present" : formattedDate(exp.endDate))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(exp.title) at \(exp.company), \(exp.location), \(formattedDate(exp.startDate)) to \(exp.isCurrent ? "present" : formattedDate(exp.endDate))")
                    }
                }
                .onDelete { indices in
                    model.remove(at: indices)
                    try? resumeModel.save()
                }
            }
            .navigationTitle("Experience")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingExperience = nil
                        showEditor = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityLabel("Add new experience")
                }
            }
            .sheet(isPresented: $showEditor) {
                ExperienceEditorView(
                    experience: editingExperience,
                    onSave: { newExp in
                        if let existing = editingExperience, let idx = model.items.firstIndex(where: { $0.id == existing.id }) {
                            model.items[idx] = newExp
                        } else {
                            model.add(newExp)
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
