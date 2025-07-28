//
//  SkillsListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//


import SwiftUI

struct SkillsListView: View {
    @Bindable var model: SkillsModel
    var resumeModel: ResumeEditorModel
    @State private var editingSkill: Skill?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { skill in
                    Button {
                        editingSkill = skill
                        showEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(skill.name)
                                .font(.headline)
                            if !skill.category.isEmpty {
                                Text(skill.category)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(skill.name), \(skill.category)")
                    }
                }
                .onDelete { indices in
                    model.remove(at: indices)
                    try? resumeModel.save()
                }
            }
            .navigationTitle("Skills")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingSkill = nil
                        showEditor = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityLabel("Add new skill")
                }
            }
            .sheet(isPresented: $showEditor) {
                SkillEditorView(
                    skill: editingSkill,
                    onSave: { newSkill in
                        if let existing = editingSkill, let idx = model.items.firstIndex(where: { $0.id == existing.id }) {
                            model.items[idx] = newSkill
                        } else {
                            model.add(newSkill)
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
}
