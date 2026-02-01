//
//  ExperienceListView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ExperienceListView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  @Bindable var model: ExperienceModel
  @State private var editorContext: ExperienceEditorContext?

  private struct ExperienceEditorContext: Identifiable {
    let id = UUID()
    let experience: WorkExperience?
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.items) { exp in
          HStack {
            ExperienceRowView(
              experience: exp,
              language: resumeModel.resume.contentLanguage
            ) {
              // Re-fetch fresh instance by id before opening editor
              let id = exp.id
              if let fresh = model.items.first(where: { $0.id == id }) {
                editorContext = ExperienceEditorContext(experience: fresh)
              } else {
                editorContext = ExperienceEditorContext(experience: exp)
              }
            }
            Spacer()
            Toggle(
              isOn: Binding(
                get: { exp.isVisible },
                set: { newValue in
                  exp.isVisible = newValue
                  try? resumeModel.save()
                }
              )
            ) {
              Image(systemName: exp.isVisible ? "eye" : "eye.slash")
                .accessibilityLabel(exp.isVisible ? "Sichtbar" : "Ausgeblendet")
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
      .navigationTitle("Berufserfahrung")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { EditButton() }
        ToolbarItem(placement: .primaryAction) {
          Button {
            editorContext = ExperienceEditorContext(experience: nil)
          } label: {
            Label("Hinzufügen", systemImage: "plus")
          }
          .accessibilityLabel("Neue Berufserfahrung hinzufügen")
        }
      }
      .sheet(item: $editorContext) { context in
        ExperienceEditorView(
          experience: context.experience,
          onSave: { newExp, language in
            if let existing = context.experience {
              existing.setTitle(newExp.title, for: language)
              existing.setCompany(newExp.company, for: language)
              existing.setLocation(newExp.location, for: language)
              existing.startDate = newExp.startDate
              existing.endDate = newExp.endDate
              existing.isCurrent = newExp.isCurrent
              existing.setDetails(newExp.details, for: language)
              existing.isVisible = true
            } else {
              if language == .english {
                newExp.title_en = newExp.title
                newExp.company_en = newExp.company
                newExp.location_en = newExp.location
                newExp.details_en = newExp.details
                newExp.title = ""
                newExp.company = ""
                newExp.location = ""
                newExp.details = ""
              }
              model.add(newExp)
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

struct ExperienceRowView: View {
  let experience: WorkExperience
  let language: ResumeLanguage
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      let fallback = language.fallback
      let title = experience.title(for: language, fallback: fallback)
      let company = experience.company(for: language, fallback: fallback)
      let location = experience.location(for: language, fallback: fallback)
      let today = String(localized: "resume.label.today", locale: language.locale)
      VStack(alignment: .leading, spacing: 4) {
        Text("\(title), \(company)")
          .font(.headline)
        HStack {
          Text(location)
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Spacer()
          Text(
            "\(formattedDate(experience.startDate)) - \(experience.isCurrent ? today : formattedDate(experience.endDate))"
          )
          .font(.caption)
          .foregroundStyle(.tertiary)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(
        "\(title) \(String(localized: "resume.label.at", locale: language.locale)) \(company), \(location), \(formattedDate(experience.startDate)) bis \(experience.isCurrent ? today : formattedDate(experience.endDate))"
      )
    }
  }

  private func formattedDate(_ date: Date?) -> String {
    guard let date else { return "-" }
    return DateFormatter.resumeMonthYear(for: language).string(from: date)
  }
}
