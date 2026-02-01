import SwiftUI

struct SkillEditorView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel

  @State private var name: String = ""
  @State private var category: String = ""
  @State private var selectedLanguage: ResumeLanguage = .defaultContent

  var onSave: (Skill, ResumeLanguage) -> Void
  var onCancel: () -> Void

  private let initialSkill: Skill?

  init(
    skill: Skill?,
    onSave: @escaping (Skill, ResumeLanguage) -> Void,
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
        Section("Sprache") {
          ResumeLanguagePicker(
            titleKey: "Bearbeitungssprache",
            selection: $selectedLanguage
          )
        }
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
            onSave(skill, selectedLanguage)
          }
          .disabled(name.isEmpty)
        }
      }
      .onAppear {
        selectedLanguage = resumeModel.resume.contentLanguage
        loadFields(for: selectedLanguage)
      }
      .onChange(of: selectedLanguage) { _, newValue in
        resumeModel.resume.contentLanguage = newValue
        try? resumeModel.save()
        loadFields(for: newValue)
      }
    }
  }

  private func loadFields(for language: ResumeLanguage) {
    guard let s = initialSkill else {
      name = ""
      category = ""
      return
    }
    let fallback: ResumeLanguage? = nil
    name = s.name(for: language, fallback: fallback)
    category = s.category(for: language, fallback: fallback)
  }
}
