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

  var body: some View {
    Form {
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
      text = resumeModel.resume.miscellaneous ?? ""
    }
  }

  private func save() {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    resumeModel.resume.miscellaneous = trimmed.isEmpty ? nil : trimmed
    resumeModel.resume.updated = .now
    try? resumeModel.save()
  }
}
