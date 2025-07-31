//
//  ExperienceListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExperienceListView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Bindable var model: ExperienceModel
    @State private var editingExperience: WorkExperience?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { exp in
                    HStack {
                        ExperienceRowView(experience: exp) {
                            // Re-fetch fresh instance by id before opening editor
                            let id = exp.id
                            if let fresh = model.items.first(where: { $0.id == id }) {
                                editingExperience = fresh
                            } else {
                                editingExperience = exp
                            }
                            showEditor = true
                        }
                        Spacer()
                        Toggle(
                            isOn: Binding(
                                get: { exp.isVisible },
                                set: { newValue in
                                    exp.isVisible = newValue
                                    try? resumeModel.save()
                                }
                            )
                        ) {
                            Image(systemName: exp.isVisible ? "eye" : "eye.slash")
                                .accessibilityLabel(exp.isVisible ? "Visible" : "Hidden")
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
                        if let existing = editingExperience {
                            existing.title = newExp.title
                            existing.company = newExp.company
                            existing.location = newExp.location
                            existing.startDate = newExp.startDate
                            existing.endDate = newExp.endDate
                            existing.isCurrent = newExp.isCurrent
                            existing.details = newExp.details
                            existing.isVisible = true
                        } else {
                            model.add(newExp)
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

struct ExperienceRowView: View {
    let experience: WorkExperience
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(experience.title), \(experience.company)")
                    .font(.headline)
                HStack {
                    Text(experience.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(
                        "\(formattedDate(experience.startDate)) - \(experience.isCurrent ? "Present" : formattedDate(experience.endDate))"
                    )
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(experience.title) at \(experience.company), \(experience.location), \(formattedDate(experience.startDate)) to \(experience.isCurrent ? "present" : formattedDate(experience.endDate))"
            )
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return DateFormatter.resumeMonthYear.string(from: date)
    }
}
