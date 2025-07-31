//
//  SkillsListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//


import SwiftUI

struct SkillsListView: View {
    @Bindable var model: SkillsModel
    @Environment(ResumeEditorModel.self) private var resumeModel
    @State private var editingSkill: Skill?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { skill in
                    HStack {
                        Button {
                            editingSkill = skill
                            showEditor = true
                        } label: {
                            Text(skill.name)
                                .font(.headline)
                        }
                        Spacer()
                        Toggle(isOn: Binding(
                            get: { skill.isVisible },
                            set: { newValue in
                                skill.isVisible = newValue
                                try? resumeModel.save()
                            }
                        )) {
                            Image(systemName: skill.isVisible ? "eye" : "eye.slash")
                                .accessibilityLabel(skill.isVisible ? "Visible" : "Hidden")
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
                        if let existing = editingSkill {
                        existing.name = newSkill.name
                        existing.category = newSkill.category
                        existing.isVisible = true
                        // resume link remains intact on existing
                        } else {
                        model.add(newSkill) // model.add sets resume and appends
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
