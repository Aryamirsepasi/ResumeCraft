import SwiftUI

struct SkillEditorView: View {
  @State private var name: String = ""
  @State private var name_de: String = ""
  @State private var category: String = ""
  @State private var category_de: String = ""

  var onSave: (Skill) -> Void
  var onCancel: () -> Void

  private let initialSkill: Skill?

  init(
    skill: Skill?,
    onSave: @escaping (Skill) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.initialSkill = skill
    self.onSave = onSave
    self.onCancel = onCancel
    // Defer population to onAppear
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Skill") {
          TextField("Name", text: $name)
            .autocapitalization(.words)
            .accessibilityLabel("Skill Name")
          TextField("Category", text: $category)
            .autocapitalization(.words)
            .accessibilityLabel("Skill Category")
        }

        Section("German Translation") {
          TextField("Name (German)", text: $name_de)
          TextField("Category (German)", text: $category_de)
        }
      }
      .navigationTitle("Edit Skill")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let skill = Skill(name: name, category: category)
            skill.name_de = name_de.isEmpty ? nil : name_de
            skill.category_de = category_de.isEmpty ? nil : category_de
            onSave(skill)
          }
          .disabled(name.isEmpty)
        }
      }
      .onAppear {
        if let s = initialSkill {
          name = s.name
          name_de = s.name_de ?? ""
          category = s.category
          category_de = s.category_de ?? ""
        }
      }
    }
  }
}
