//
//  LanguageEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct LanguageEditorView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel

  @State private var name: String = ""
  @State private var proficiency: String = ""
  @State private var selectedLanguage: ResumeLanguage = .defaultContent

  var onSave: (Language, ResumeLanguage) -> Void
  var onCancel: () -> Void
  private let initialLanguage: Language?

  init(
    language: Language?,
    onSave: @escaping (Language, ResumeLanguage) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.initialLanguage = language
    self.onSave = onSave
    self.onCancel = onCancel
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Bearbeitungssprache") {
          ResumeLanguagePicker(
            titleKey: "Bearbeitungssprache",
            selection: $selectedLanguage
          )
        }
        Section("Sprache") {
          TextField("Sprache", text: $name)
        }
        Section("Kenntnisstand") {
          Picker("Kenntnisstand", selection: $proficiency) {
            ForEach(proficiencies(for: selectedLanguage), id: \.self) { level in
              Text(level)
            }
          }
          .pickerStyle(.menu)
        }
      }
      .navigationTitle("Sprache bearbeiten")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Abbrechen", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Speichern") {
            let lang = Language(name: name, proficiency: proficiency)
            onSave(lang, selectedLanguage)
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

  private func proficiencies(for language: ResumeLanguage) -> [String] {
    switch language {
    case .german:
      return ["Muttersprache", "Fließend", "Beruflich", "Fortgeschritten", "Grundkenntnisse"]
    case .english:
      return ["Native", "Fluent", "Professional", "Intermediate", "Basic"]
    }
  }

  private func loadFields(for language: ResumeLanguage) {
    guard let lang = initialLanguage else {
      name = ""
      proficiency = language == .english ? "Fluent" : "Fließend"
      return
    }
    let fallback: ResumeLanguage? = nil
    name = lang.name(for: language, fallback: fallback)
    proficiency = lang.proficiency(for: language, fallback: fallback)
    if proficiency.isEmpty {
      proficiency = language == .english ? "Fluent" : "Fließend"
    }
  }
}
