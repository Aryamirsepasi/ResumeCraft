
import SwiftUI

struct SkillEditorView: View {
    @State private var name: String
    @State private var category: String

    var onSave: (Skill) -> Void
    var onCancel: () -> Void

    init(
        skill: Skill?,
        onSave: @escaping (Skill) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _name = State(initialValue: skill?.name ?? "")
        _category = State(initialValue: skill?.category ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
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
        }
    }
}
