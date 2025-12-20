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
  @State private var editorContext: LanguageEditorContext?

  private struct LanguageEditorContext: Identifiable {
    let id = UUID()
    let language: Language?
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { lang in
          HStack {
            LanguageRowView(language: lang) {
              // Re-fetch fresh instance by id before opening editor
              let id = lang.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editorContext = LanguageEditorContext(language: fresh)
              } else {
                editorContext = LanguageEditorContext(language: lang)
              }
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
                .accessibilityLabel(lang.isVisible ? "Sichtbar" : "Ausgeblendet")
            }
            .labelsHidden()
            .toggleStyle(.button)
          }
        }
        .onMove { indices, newOffset in
          model.move(from: indices, to: newOffset)
          try? resumeModel.save()
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
      .navigationTitle("Sprachen")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editorContext = LanguageEditorContext(language: nil)
          } label: {
            Label("Hinzufügen", systemImage: "plus")
          }
          .accessibilityLabel("Neue Sprache hinzufügen")
        }
      }
      .sheet(item: $editorContext) { context in
        LanguageEditorView(
          language: context.language,
          onSave: { newLang in
            if let existing = context.language {
              existing.name = newLang.name
              existing.proficiency = newLang.proficiency
              existing.isVisible = true
            } else {
              model.add(newLang)
            }
            editorContext = nil
            try? resumeModel.save()
          },
          onCancel: { editorContext = nil }
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
        Text(language.name).font(.headline)
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
