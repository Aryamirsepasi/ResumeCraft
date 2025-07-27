//
//  ExtracurricularListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExtracurricularListView: View {
    let model: ExtracurricularModel
    var resumeModel: ResumeEditorModel
    @State private var editingActivity: Extracurricular?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                LazyVStack {
                    ForEach(model.items, id: \.id) { activity in
                        activityButton(for: activity)
                    }
                    .onDelete { indices in
                        model.remove(at: indices)
                        try? resumeModel.save()
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
                        if let existing = editingActivity,
                           let idx = model.items.firstIndex(where: { $0.id == existing.id }) {
                            model.update(newActivity, at: idx)
                        } else {
                            model.add(newActivity)
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

    @ViewBuilder
    private func activityButton(for activity: Extracurricular) -> some View {
        Button {
            editingActivity = activity
            showEditor = true
        } label: {
            ExtracurricularRowView(activity: activity)
        }
        .accessibilityLabel("\(activity.title) at \(activity.organization), \(activity.dscription)")
        .accessibilityHint("Tap to edit this activity")
    }
}

struct ExtracurricularRowView: View {
    let activity: Extracurricular

    var body: some View {
        VStack(alignment: .leading) {
            Text(activity.title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(activity.organization)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(activity.dscription)
                .font(.body)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }
}
