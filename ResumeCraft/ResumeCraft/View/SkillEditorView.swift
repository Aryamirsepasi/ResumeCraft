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
                Section("Skill") {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                        .accessibilityLabel("Skill Name")
                    TextField("Category", text: $category)
                        .autocapitalization(.words)
                        .accessibilityLabel("Skill Category")
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
