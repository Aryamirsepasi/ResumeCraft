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

    private let proficiencies = ["Native", "Fluent", "Professional", "Intermediate", "Basic"]

    var onSave: (Language) -> Void
    var onCancel: () -> Void

    init(
        language: Language?,
        onSave: @escaping (Language) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _name = State(initialValue: language?.name ?? "")
        _proficiency = State(initialValue: language?.proficiency ?? "Fluent")
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
            }
            .navigationTitle("Edit Language")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let lang = Language(
                            name: name,
                            proficiency: proficiency
                        )
                        onSave(lang)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
