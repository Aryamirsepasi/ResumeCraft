//
//  LanguageEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct LanguageEditorView: View {
  @State private var name: String
  @State private var proficiency: String

  private let proficiencies = [
    "Muttersprache", "Fließend", "Beruflich", "Fortgeschritten", "Grundkenntnisse",
  ]

  var onSave: (Language) -> Void
  var onCancel: () -> Void

  init(
    language: Language?,
    onSave: @escaping (Language) -> Void,
    onCancel: @escaping () -> Void
  ) {
    _name = State(initialValue: language?.name ?? "")
    _proficiency = State(initialValue: language?.proficiency ?? "Fließend")
    self.onSave = onSave
    self.onCancel = onCancel
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Sprache") {
          TextField("Sprache", text: $name)
        }
        Section("Kenntnisstand") {
          Picker("Kenntnisstand", selection: $proficiency) {
            ForEach(proficiencies, id: \.self) { level in
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
            onSave(lang)
          }
          .disabled(name.isEmpty)
        }
      }
    }
  }
}
