//
//  LanguagesListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct LanguagesListView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Bindable var model: LanguageModel
    @State private var editingLanguage: Language?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { lang in
                    HStack {
                        LanguageRowView(language: lang) {
                            // Re-fetch fresh instance by id before opening editor
                            let id = lang.id
                            if let fresh = model.items.first(where: { $0.id == id }) {
                                editingLanguage = fresh
                            } else {
                                editingLanguage = lang
                            }
                            showEditor = true
                        }
                        Spacer()
                        Toggle(
                            isOn: Binding(
                                get: { lang.isVisible },
                                set: { newValue in
                                    lang.isVisible = newValue
                                    try? resumeModel.save()
                                }
                            )
                        ) {
                            Image(systemName: lang.isVisible ? "eye" : "eye.slash")
                                .accessibilityLabel(lang.isVisible ? "Visible" : "Hidden")
                        }
                        .labelsHidden()
                        .toggleStyle(.button)
                    }
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
            .navigationTitle("Languages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingLanguage = nil
                        showEditor = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .accessibilityLabel("Add new language")
                }
            }
            .sheet(isPresented: $showEditor) {
                LanguageEditorView(
                    language: editingLanguage,
                    onSave: { newLang in
                        if let existing = editingLanguage {
                            existing.name = newLang.name
                            existing.proficiency = newLang.proficiency
                            existing.isVisible = true
                        } else {
                            model.add(newLang)
                        }
                        showEditor = false
                        try? resumeModel.save()
                    },
                    onCancel: { showEditor = false }
                )
            }
        }
    }
}

struct LanguageRowView: View {
    let language: Language
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(language.name)
                    .font(.headline)
                Spacer()
                Text(language.proficiency)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(language.name), \(language.proficiency)")
        }
    }
}
