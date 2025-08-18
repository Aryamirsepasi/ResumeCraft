//
//  LanguageEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct LanguageEditorView: View {
  @State private var name: String
  @State private var name_de: String
  @State private var proficiency: String
  @State private var proficiency_de: String

  private let proficiencies = [
    "Native", "Fluent", "Professional", "Intermediate", "Basic",
  ]

  var onSave: (Language) -> Void
  var onCancel: () -> Void

  init(
    language: Language?,
    onSave: @escaping (Language) -> Void,
    onCancel: @escaping () -> Void
  ) {
    _name = State(initialValue: language?.name ?? "")
    _name_de = State(initialValue: language?.name_de ?? "")
    _proficiency = State(initialValue: language?.proficiency ?? "Fluent")
    _proficiency_de = State(initialValue: language?.proficiency_de ?? "")
    self.onSave = onSave
    self.onCancel = onCancel
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Language") {
          TextField("Language", text: $name)
        }
        Section("Proficiency") {
          Picker("Proficiency", selection: $proficiency) {
            ForEach(proficiencies, id: \.self) { level in
              Text(level)
            }
          }
          .pickerStyle(.menu)
        }
        Section("German Translation") {
          TextField("Language (German)", text: $name_de)
          TextField("Proficiency (German)", text: $proficiency_de)
        }
      }
      .navigationTitle("Edit Language")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let lang = Language(name: name, proficiency: proficiency)
            lang.name_de = name_de.isEmpty ? nil : name_de
            lang.proficiency_de =
              proficiency_de.isEmpty ? nil : proficiency_de
            onSave(lang)
          }
          .disabled(name.isEmpty)
        }
      }
    }
  }
}
