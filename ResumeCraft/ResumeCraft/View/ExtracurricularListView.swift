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
    @State private var editingActivity: Extracurricular?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { activity in
                    HStack {
                        ExtracurricularRowView(activity: activity) {
                            // Re-fetch fresh instance by id before opening editor
                            let id = activity.id
                            if let fresh = model.items.first(where: { $0.id == id }) {
                                editingActivity = fresh
                            } else {
                                editingActivity = activity
                            }
                            showEditor = true
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
                                .accessibilityLabel(activity.isVisible ? "Visible" : "Hidden")
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
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingActivity = nil
                        showEditor = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityLabel("Add new activity")
                }
            }
            .sheet(isPresented: $showEditor) {
                ExtracurricularEditorView(
                    activity: editingActivity,
                    onSave: { newActivity in
                        if let existing = editingActivity {
                            existing.title = newActivity.title
                            existing.organization = newActivity.organization
                            existing.details = newActivity.details
                            existing.isVisible = true
                        } else {
                            model.add(newActivity)
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
                "\(activity.title) at \(activity.organization), \(activity.details)"
            )
            .accessibilityHint("Tap to edit this activity")
        }
    }
}
