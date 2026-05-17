//
//  HomeView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 06.08.25.
//

import SwiftUI
import FoundationModels
@preconcurrency import Translation

struct HomeView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  let openPreview: () -> Void
  let importPDF: () -> Void
  let openSettings: () -> Void

  @State private var translationConfig: TranslationSession.Configuration?
  @State private var isTranslating = false
  @State private var translationResultMessage: String?
  @State private var showTranslationResult = false
  @State private var translationDirection: ResumeTranslationService.Direction = .germanToEnglish

  var body: some View {
    NavigationStack {
      List {
        // Quick Actions Section with visual hierarchy
        Section {
          Button(action: { importPDF() }) {
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text("Aus PDF importieren")
                  .font(.headline)
                Text(importSubtitle)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: "doc.richtext.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.title2)
                .foregroundStyle(.blue)
            }
          }
          .disabled(!canUseAppleIntelligence)
          .accessibilityHint(Text(importAccessibilityHint))
          .listRowBackground(Color.clear)

          Button(action: { triggerTranslation() }) {
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text(translationTitle)
                  .font(.headline)
                Text("home.translate.subtitle")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            } icon: {
              if isTranslating {
                ProgressView()
                  .frame(width: 24, height: 24)
              } else {
                Image(systemName: "globe")
                  .symbolRenderingMode(.hierarchical)
                  .font(.title2)
                  .foregroundStyle(.green)
              }
            }
          }
          .disabled(isTranslating)
          .accessibilityHint(Text("home.translate.hint"))
          .listRowBackground(Color.clear)
        } header: {
          Text("Schnellaktionen")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        
        // Resume Stats Section
        Section {
          ResumeStatsRow(resumeModel: resumeModel)
        } header: {
          Text("Lebenslauf-Übersicht")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        
        // Edit Sections with better visual grouping
        Section {
          HomeRow(
            title: Text("Persönliche Daten"),
            subtitle: Text("Name, Kontakt, Links"),
            systemImage: "person.circle.fill",
            iconColor: .blue,
            destination: { PersonalInfoView(model: resumeModel.personalModel) }
          )
          HomeRow(
            title: Text("Zusammenfassung"),
            subtitle: Text("Kurze Einführung unter persönlichen Daten"),
            systemImage: "text.justify",
            iconColor: .purple,
            destination: { SummaryEditorView() }
          )
        } header: {
          Text("Grundinformationen")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        
        Section {
          HomeRow(
            title: Text("Berufserfahrung"),
            subtitle: Text("Positionen und Aufgaben"),
            systemImage: "briefcase.fill",
            iconColor: .orange,
            destination: { ExperienceListView(model: resumeModel.experienceModel) }
          )
          HomeRow(
            title: Text("Projekte"),
            subtitle: Text("Private und berufliche Projekte"),
            systemImage: "hammer.fill",
            iconColor: .green,
            destination: { ProjectsListView(model: resumeModel.projectsModel) }
          )
          HomeRow(
            title: Text("Fähigkeiten"),
            subtitle: Text("Technische und soziale Fähigkeiten"),
            systemImage: "star.circle.fill",
            iconColor: .yellow,
            destination: { SkillsListView(model: resumeModel.skillsModel) }
          )
        } header: {
          Text("Beruflich")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
        
        Section {
          HomeRow(
            title: Text("Ausbildung"),
            subtitle: Text("Abschlüsse, Daten, Details"),
            systemImage: "graduationcap.fill",
            iconColor: .indigo,
            destination: { EducationListView(model: resumeModel.educationModel) }
          )
          HomeRow(
            title: Text("Aktivitäten"),
            subtitle: Text("Vereine, Ehrenamt, mehr"),
            systemImage: "figure.wave",
            iconColor: .pink,
            destination: { ExtracurricularListView(model: resumeModel.extracurricularModel) }
          )
          HomeRow(
            title: Text("Sprachen"),
            subtitle: Text("Sprachen und Kenntnisstand"),
            systemImage: "globe.americas.fill",
            iconColor: .teal,
            destination: { LanguagesListView(model: resumeModel.languageModel) }
          )
          HomeRow(
            title: Text("Sonstiges"),
            subtitle: Text("Weitere Informationen und Hinweise"),
            systemImage: "ellipsis.circle.fill",
            iconColor: .gray,
            destination: { MiscellaneousEditorView() }
          )
        } header: {
          Text("Zusätzliches")
            .font(.subheadline)
            .fontWeight(.semibold)
        }
      }
      .listSectionSpacing(16)
      .navigationTitle("ResumeCraft")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: openPreview) {
            Label("Vorschau", systemImage: "doc.text.magnifyingglass")
          }
          .tint(.blue)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: openSettings) {
            Label("Einstellungen", systemImage: "gearshape")
          }
        }
      }
      .translationTask(translationConfig) { session in
        await performTranslation(session: session)
      }
      .alert("home.translate.alertTitle", isPresented: $showTranslationResult) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(translationResultMessage ?? "")
      }
    }
  }

  /// Picks the translation direction based on the resume's content language.
  /// If the user works in German, translate German -> English; otherwise the reverse.
  private var preferredDirection: ResumeTranslationService.Direction {
    switch resumeModel.resume.contentLanguage {
    case .german: return .germanToEnglish
    case .english: return .englishToGerman
    }
  }

  private var canUseAppleIntelligence: Bool {
    if case .available = SystemLanguageModel.default.availability {
      return true
    }
    return false
  }

  private var importSubtitle: LocalizedStringKey {
    canUseAppleIntelligence
      ? "Abschnitte automatisch extrahieren und ausfüllen"
      : "Apple Intelligence für PDF-Import erforderlich"
  }

  private var importAccessibilityHint: LocalizedStringKey {
    canUseAppleIntelligence
      ? "Importiere deinen Lebenslauf als PDF und fülle Abschnitte automatisch aus."
      : "Aktiviere Apple Intelligence, um PDF-Import zu verwenden."
  }

  /// Localized button title that reflects the direction.
  private var translationTitle: LocalizedStringKey {
    switch preferredDirection {
    case .germanToEnglish: return "home.translate.toEnglish"
    case .englishToGerman: return "home.translate.toGerman"
    }
  }

  private func triggerTranslation() {
    guard !isTranslating else { return }
    let direction = preferredDirection
    translationDirection = direction
    let newConfig = TranslationSession.Configuration(
      source: direction.sourceLanguage,
      target: direction.targetLanguage
    )
    if translationConfig == nil {
      translationConfig = newConfig
    } else {
      // Force a fresh session — invalidate completes any in-flight task, then
      // we reassign to a new config so the Apple Translation framework picks
      // up the (possibly new) direction.
      translationConfig?.invalidate()
      translationConfig = newConfig
    }
  }

  @MainActor
  private func performTranslation(session: TranslationSession) async {
    isTranslating = true
    defer { isTranslating = false }

    let direction = translationDirection
    let requestBatch = TranslationRequestBatch(
      requests: ResumeTranslationService.buildRequests(
        from: resumeModel.resume,
        direction: direction,
        mode: .refreshAll
      )
    )

    guard !requestBatch.isEmpty else {
      translationResultMessage = String(localized: "home.translate.empty")
      showTranslationResult = true
      return
    }

    do {
      let responses = try await requestBatch.translations(using: session)
      ResumeTranslationService.applyTranslations(responses, to: resumeModel.resume, direction: direction)
      try resumeModel.save()
      let template = String(localized: "home.translate.success")
      translationResultMessage = String(format: template, responses.count)
      showTranslationResult = true
    } catch {
      let template = String(localized: "home.translate.failed")
      translationResultMessage = String(format: template, error.localizedDescription)
      showTranslationResult = true
    }
  }
}

private struct TranslationRequestBatch: @unchecked Sendable {
  let requests: [TranslationSession.Request]

  var isEmpty: Bool {
    requests.isEmpty
  }

  func translations(using session: TranslationSession) async throws -> [TranslationSession.Response] {
    try await session.translations(from: requests)
  }
}

private struct HomeRow<Destination: View>: View {
  let title: Text
  let subtitle: Text
  let systemImage: String
  let iconColor: Color
  @ViewBuilder let destination: () -> Destination

  var body: some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(iconColor.gradient)
            .frame(width: 40, height: 40)
          
          Image(systemName: systemImage)
            .symbolRenderingMode(.hierarchical)
            .font(.title3)
            .foregroundStyle(.white)
        }
        
        VStack(alignment: .leading, spacing: 3) {
          title
            .font(.headline)
            .foregroundStyle(.primary)
          subtitle
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.vertical, 4)
    }
  }
}
// New Resume Stats Row
private struct ResumeStatsRow: View {
  let resumeModel: ResumeEditorModel
  
  var body: some View {
    HStack(spacing: 20) {
      StatBadge(
        icon: "briefcase.fill",
        count: (resumeModel.resume.experiences ?? []).filter(\.isVisible).count,
        label: String(localized: "Positionen"),
        color: .orange
      )
      
      StatBadge(
        icon: "graduationcap.fill",
        count: (resumeModel.resume.educations ?? []).filter(\.isVisible).count,
        label: String(localized: "Ausbildung"),
        color: .indigo
      )
      
      StatBadge(
        icon: "star.fill",
        count: (resumeModel.resume.skills ?? []).filter(\.isVisible).count,
        label: String(localized: "Fähigkeiten"),
        color: .yellow
      )
      
      StatBadge(
        icon: "hammer.fill",
        count: (resumeModel.resume.projects ?? []).filter(\.isVisible).count,
        label: String(localized: "Projekte"),
        color: .green
      )
    }
    .padding(.vertical, 8)
  }
}

private struct StatBadge: View {
  let icon: String
  let count: Int
  let label: String
  let color: Color
  
  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: icon)
        .font(.title3)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(color)
      
      Text("\(count)")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundStyle(.primary)
      
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}
