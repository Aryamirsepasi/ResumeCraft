import SwiftUI

struct SkillEditorView: View {
  @State private var name: String = ""
  @State private var category: String = ""

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
        Section("Fähigkeit") {
          TextField("Name", text: $name)
            .autocapitalization(.words)
            .accessibilityLabel("Fähigkeit")
          TextField("Kategorie", text: $category)
            .autocapitalization(.words)
            .accessibilityLabel("Kategorie")
        }
      }
      .navigationTitle("Fähigkeit bearbeiten")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Abbrechen", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Speichern") {
            let skill = Skill(name: name, category: category)
            onSave(skill)
          }
          .disabled(name.isEmpty)
        }
      }
      .onAppear {
        if let s = initialSkill {
          name = s.name
          category = s.category
        }
      }
    }
  }
}
