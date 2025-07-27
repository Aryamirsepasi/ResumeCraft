//
//  LanguagesListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct LanguagesListView: View {
    @Bindable var model: LanguageModel
    var resumeModel: ResumeEditorModel
    @State private var editingLanguage: Language?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.items) { lang in
                    Button {
                        editingLanguage = lang
                        showEditor = true
                    } label: {
                        HStack {
                            Text(lang.name)
                                .font(.headline)
                            Spacer()
                            Text(lang.proficiency)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(lang.name), \(lang.proficiency)")
                    }
                }
                .onDelete { indices in
                    model.remove(at: indices)
                    try? resumeModel.save()
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
                        if let existing = editingLanguage, let idx = model.items.firstIndex(where: { $0.id == existing.id }) {
                            model.items[idx] = newLang
                        } else {
                            model.add(newLang)
                        }
                        showEditor = false
                        try? resumeModel.save()
                    },
                    onCancel: {
                        showEditor = false
                    }
                )
            }
        }
    }
}
