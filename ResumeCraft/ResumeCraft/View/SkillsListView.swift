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
  @State private var editorContext: SkillEditorContext?

  private struct SkillEditorContext: Identifiable {
    let id = UUID()
    let skill: Skill?
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { skill in
          HStack {
            Button {
              // Re-fetch fresh instance by id before opening editor
              let id = skill.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editorContext = SkillEditorContext(skill: fresh)
              } else {
                editorContext = SkillEditorContext(skill: skill)
              }
            } label: {
              Text(skill.name).font(.headline)
            }
            Spacer()
            Toggle(
              isOn: Binding(
                get: { skill.isVisible },
                set: { newValue in
                  skill.isVisible = newValue
                  try? resumeModel.save()
                }
              )
            ) {
              Image(systemName: skill.isVisible ? "eye" : "eye.slash")
                .accessibilityLabel(skill.isVisible ? "Sichtbar" : "Ausgeblendet")
            }
            .labelsHidden()
            .toggleStyle(.button)
          }
        }
        .onMove { indices, newOffset in
          model.move(from: indices, to: newOffset)
          try? resumeModel.save()
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
      .navigationTitle("Fähigkeiten")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editorContext = SkillEditorContext(skill: nil)
          } label: {
            Label("Hinzufügen", systemImage: "plus")
          }
          .accessibilityLabel("Neue Fähigkeit hinzufügen")
        }
      }
      .sheet(item: $editorContext) { context in
        SkillEditorView(
          skill: context.skill,
          onSave: { newSkill in
            if let existing = context.skill {
              existing.name = newSkill.name
              existing.category = newSkill.category
              existing.isVisible = true
            } else {
              model.add(newSkill)
            }
            editorContext = nil
            try? resumeModel.save()
          },
          onCancel: { editorContext = nil }
        )
      }
    }
  }
}
