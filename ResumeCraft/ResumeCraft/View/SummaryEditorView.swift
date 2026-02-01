//
//  SummaryEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 07.08.25.
//

import SwiftUI

struct SummaryEditorView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  @Environment(\.modelContext) private var context

  @State private var text: String = ""
  @State private var isVisible: Bool = true
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
          .overlay(alignment: .bottomTrailing) {
            Text("\(text.count)/600")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .padding(8)
          }
      } header: { Text("Zusammenfassung") }
        footer: {
          Text(
            "Eine kurze Übersicht von 2–4 Sätzen, die Ihre Rolle, Stärken und Ziele hervorhebt."
          )
        }

      Toggle("Im Lebenslauf anzeigen", isOn: $isVisible)
    }
    .navigationTitle("Zusammenfassung")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Speichern") { save() }.bold()
      }
    }
    .onAppear {
      let s = resumeModel.resume.summary
      selectedLanguage = resumeModel.resume.contentLanguage
      text = s?.text(for: selectedLanguage, fallback: nil) ?? ""
      isVisible = s?.isVisible ?? true
    }
    .onChange(of: selectedLanguage) { _, newValue in
      resumeModel.resume.contentLanguage = newValue
      try? resumeModel.save()
      text = resumeModel.resume.summary?.text(for: newValue, fallback: nil) ?? ""
    }
  }

  private func save() {
    if resumeModel.resume.summary == nil {
      let s = Summary(text: "", isVisible: isVisible)
      s.setText(text, for: selectedLanguage)
      s.resume = resumeModel.resume
      resumeModel.resume.summary = s
      context.insert(s)
    } else {
      resumeModel.resume.summary?.setText(text, for: selectedLanguage)
      resumeModel.resume.summary?.isVisible = isVisible
    }
    resumeModel.resume.updated = Date()
    try? resumeModel.save()
  }
}
