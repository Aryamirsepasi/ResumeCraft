//
//  MiscellaneousEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 20.10.25.
//

import SwiftUI

struct MiscellaneousEditorView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  @State private var text: String = ""
  @State private var selectedLanguage: ResumeLanguage = .defaultContent

  var body: some View {
    Form {
      Section("Sprache") {
        ResumeLanguagePicker(
          titleKey: "Bearbeitungssprache",
          selection: $selectedLanguage
        )
      }
      Section {
        TextEditor(text: $text)
          .frame(minHeight: 180)
          .textInputAutocapitalization(.sentences)
      } header: {
        Text("Sonstiges")
      }
    }
    .navigationTitle("Sonstiges")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Speichern") { save() }.bold()
      }
    }
    .onAppear {
      selectedLanguage = resumeModel.resume.contentLanguage
      text = resumeModel.resume.miscellaneous(for: selectedLanguage, fallback: nil)
    }
    .onChange(of: selectedLanguage) { _, newValue in
      resumeModel.resume.contentLanguage = newValue
      try? resumeModel.save()
      text = resumeModel.resume.miscellaneous(for: newValue, fallback: nil)
    }
  }

  private func save() {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    resumeModel.resume.setMiscellaneous(trimmed, for: selectedLanguage)
    resumeModel.resume.updated = .now
    try? resumeModel.save()
  }
}
