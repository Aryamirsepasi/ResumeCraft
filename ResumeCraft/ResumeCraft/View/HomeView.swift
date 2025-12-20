//
//  HomeView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 06.08.25.
//

import SwiftUI

struct HomeView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  let openPreview: () -> Void
  let importPDF: () -> Void
  let openSettings: () -> Void

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
                Text("Abschnitte automatisch extrahieren und ausfüllen")
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
          .accessibilityHint("Importiere deinen Lebenslauf als PDF und fülle Abschnitte automatisch aus.")
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
            destination: AnyView(PersonalInfoView(model: resumeModel.personalModel))
          )
          HomeRow(
            title: Text("Zusammenfassung"),
            subtitle: Text("Kurze Einführung unter persönlichen Daten"),
            systemImage: "text.justify",
            iconColor: .purple,
            destination: AnyView(SummaryEditorView())
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
            destination: AnyView(ExperienceListView(model: resumeModel.experienceModel))
          )
          HomeRow(
            title: Text("Projekte"),
            subtitle: Text("Private und berufliche Projekte"),
            systemImage: "hammer.fill",
            iconColor: .green,
            destination: AnyView(ProjectsListView(model: resumeModel.projectsModel))
          )
          HomeRow(
            title: Text("Fähigkeiten"),
            subtitle: Text("Technische und soziale Fähigkeiten"),
            systemImage: "star.circle.fill",
            iconColor: .yellow,
            destination: AnyView(SkillsListView(model: resumeModel.skillsModel))
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
            destination: AnyView(EducationListView(model: resumeModel.educationModel))
          )
          HomeRow(
            title: Text("Aktivitäten"),
            subtitle: Text("Vereine, Ehrenamt, mehr"),
            systemImage: "figure.wave",
            iconColor: .pink,
            destination: AnyView(ExtracurricularListView(model: resumeModel.extracurricularModel))
          )
          HomeRow(
            title: Text("Sprachen"),
            subtitle: Text("Sprachen und Kenntnisstand"),
            systemImage: "globe.americas.fill",
            iconColor: .teal,
            destination: AnyView(LanguagesListView(model: resumeModel.languageModel))
          )
          HomeRow(
            title: Text("Sonstiges"),
            subtitle: Text("Weitere Informationen und Hinweise"),
            systemImage: "ellipsis.circle.fill",
            iconColor: .gray,
            destination: AnyView(MiscellaneousEditorView())
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
    }
  }
}

private struct HomeRow: View {
  let title: Text
  let subtitle: Text
  let systemImage: String
  let iconColor: Color
  let destination: AnyView

  var body: some View {
    NavigationLink {
      destination
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
        label: "Positionen",
        color: .orange
      )
      
      StatBadge(
        icon: "graduationcap.fill",
        count: (resumeModel.resume.educations ?? []).filter(\.isVisible).count,
        label: "Ausbildung",
        color: .indigo
      )
      
      StatBadge(
        icon: "star.fill",
        count: (resumeModel.resume.skills ?? []).filter(\.isVisible).count,
        label: "Fähigkeiten",
        color: .yellow
      )
      
      StatBadge(
        icon: "hammer.fill",
        count: (resumeModel.resume.projects ?? []).filter(\.isVisible).count,
        label: "Projekte",
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
