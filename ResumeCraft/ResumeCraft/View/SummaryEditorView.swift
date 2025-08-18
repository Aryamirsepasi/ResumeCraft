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
  @State private var text_de: String = ""
  @State private var isVisible: Bool = true

  var body: some View {
    Form {
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
      } header: { Text("Summary") }
        footer: {
          Text(
            "A concise 2–4 sentence overview highlighting your role, strengths, and goals."
          )
        }

      Section("German Translation") {
        TextEditor(text: $text_de)
          .frame(minHeight: 120)
          .textInputAutocapitalization(.sentences)
      }

      Toggle("Show on resume", isOn: $isVisible)
    }
    .navigationTitle("Summary")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Save") { save() }.bold()
      }
    }
    .onAppear {
      let s = resumeModel.resume.summary
      text = s?.text ?? ""
      text_de = s?.text_de ?? ""
      isVisible = s?.isVisible ?? true
    }
  }

  private func save() {
    if resumeModel.resume.summary == nil {
      let s = Summary(text: text, isVisible: isVisible)
      s.text_de = text_de.trimmingCharacters(
        in: .whitespacesAndNewlines
      ).isEmpty ? nil : text_de
      s.resume = resumeModel.resume
      resumeModel.resume.summary = s
      context.insert(s)
    } else {
      resumeModel.resume.summary?.text = text
      resumeModel.resume.summary?.text_de =
        text_de.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? nil : text_de
      resumeModel.resume.summary?.isVisible = isVisible
    }
    resumeModel.resume.updated = Date()
  }
}
