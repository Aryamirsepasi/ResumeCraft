import SwiftUI
import CloudKit
import FoundationModels   // iOS 26+
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Environment(\.openURL) private var openURL
    @Environment(PersistenceStatus.self) private var persistenceStatus
    
    @State private var iCloudAccountStatus: CKAccountStatus? = nil
    @State private var resumeScore: ResumeScore?
    @State private var showCloudKitDiagnostics = false

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    var body: some View {
        NavigationStack {
            List {
                // Resume Score Section
                Section {
                    if let score = resumeScore {
                        NavigationLink {
                            ResumeScoreCardView(score: score)
                        } label: {
                            ResumeScoreRowContent(score: score)
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Lebenslauf wird analysiert...")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Lebenslauf-Status")
                        .textCase(.uppercase)
                        .font(.caption)
                }

                Section("Sprache") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bearbeitungssprache")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ResumeLanguagePicker(
                            titleKey: "Bearbeitungssprache",
                            selection: contentLanguageBinding
                        )
                        .accessibilityLabel("Bearbeitungssprache")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ausgabesprache")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ResumeLanguagePicker(
                            titleKey: "Ausgabesprache",
                            selection: outputLanguageBinding
                        )
                        .accessibilityLabel("Ausgabesprache")
                    }
                    Text("Diese Auswahl steuert, in welcher Sprache du Inhalte bearbeitest und exportierst.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Smart Suggestions Link
                Section {
                    NavigationLink {
                        SmartSuggestionsListView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.purple.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.purple)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smarte Vorschläge")
                                    .font(.subheadline.weight(.medium))
                                Text("KI-gestützte Verbesserungstipps")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        VersionHistoryView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.indigo.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.indigo)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Versionsverlauf")
                                    .font(.subheadline.weight(.medium))
                                Text("Änderungen im Zeitverlauf verfolgen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Werkzeuge")
                        .textCase(.uppercase)
                        .font(.caption)
                }
                
                // On-device AI (Foundation Models) status
                Section("KI auf dem Gerät") {
                    if #available(iOS 26, *) {
                        let availability = SystemLanguageModel.default.availability

                        HStack {
                            switch availability {
                            case .available:
                                Label("Apple Intelligence: Aktiviert", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            case .unavailable(let reason):
                                Label("Apple Intelligence: Nicht verfügbar", systemImage: "xmark.octagon.fill")
                                    .foregroundStyle(.red)
                                Spacer()
                                Button("Einstellungen öffnen") {
                                    openAppSettings()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Einstellungen öffnen, um Apple Intelligence zu aktivieren")
                                .help("Grund: \(String(describing: reason))")
                            }
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Datenschutz & Verarbeitung")
                                .font(.callout).bold()
                            Text("ResumeCraft nutzt das On-Device-Sprachmodell, um deinen Lebenslauf zu prüfen. Deine Daten verlassen das Gerät nicht.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    } else {
                        Label("Erfordert iOS 26 oder neuer", systemImage: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                }

                // iCloud Status
                Section("iCloud-Status") {
                    HStack {
                        Image(systemName: persistenceStatus.isCloudKitEnabled ? "icloud.fill" : "externaldrive.fill")
                            .foregroundStyle(persistenceStatus.isCloudKitEnabled ? .blue : .orange)
                        let backendLabel: String = {
                            switch persistenceStatus.backend {
                            case .cloudKit:
                                return "Synchronisierung aktiv"
                            case .local:
                                return "Nur lokal (Sync deaktiviert)"
                            case .inMemory:
                                return "Im Speicher (nicht gespeichert)"
                            }
                        }()
                        Text(backendLabel)
                        Spacer()
                        Text(persistenceStatus.buildConfiguration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Container: \(CloudKitConfiguration.containerIdentifier)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Bundle-ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let error = persistenceStatus.cloudKitInitializationError {
                        Text("iCloud-Initialisierungsfehler: \(error)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let error = persistenceStatus.localInitializationError {
                        Text("Lokaler Speicherfehler: \(error)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let status = iCloudAccountStatus {
                        HStack {
                            switch status {
                            case .available:
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                Text("Mit iCloud verbunden")
                            case .noAccount:
                                Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                                Text("Nicht bei iCloud angemeldet (nur lokal)")
                            case .restricted:
                                Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                                Text("iCloud eingeschränkt (nur lokal)")
                            case .couldNotDetermine:
                                Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                                Text("iCloud-Status konnte nicht ermittelt werden")
                            case .temporarilyUnavailable:
                                Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                Text("iCloud vorübergehend nicht verfügbar")
                            @unknown default:
                                Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                                Text("Unbekannter iCloud-Status")
                            }
                            
                            Spacer()
                            
                            if status == .noAccount || status == .restricted {
                                Button("Einstellungen öffnen") {
                                    openAppSettings()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            ProgressView()
                            Text("iCloud wird geprüft…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Text("Hinweis: CloudKit synchronisiert nicht zwischen Debug/TestFlight/App-Store-Builds (verschiedene Umgebungen). Stelle sicher, dass beide Geräte denselben Build-Kanal nutzen.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showCloudKitDiagnostics = true
                    } label: {
                        HStack {
                            Image(systemName: "stethoscope")
                            Text("CloudKit-Diagnose ausführen")
                        }
                    }
                }

                // App info
                Section {
                    HStack {
                        Image("IconPreview")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(radius: 4)
                            .accessibilityLabel("App-Symbol")
                        VStack(alignment: .leading) {
                            Text("ResumeCraft").font(.title2).fontWeight(.bold)
                            Text("Version 1.0.0").font(.caption).foregroundStyle(.secondary)
                            Text("© 2025 Arya Mirsepasi").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // About / Links
                Section {
                    VStack(spacing: 0) {
                        AboutLinkRow(
                            iconName: "person.fill",
                            iconColor: .blue,
                            title: "App-Website",
                            subtitle: "Arya Mirsepasi",
                            url: URL(string: "https://aryamirsepasi.com/resumecraft")!
                        )
                        Divider()
                        AboutLinkRow(
                            iconName: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "Probleme?",
                            subtitle: "Melde ein neues Problem auf der Support-Seite!",
                            url: URL(string: "https://aryamirsepasi.com/support")!
                        )
                        Divider()
                        AboutLinkRow(
                            iconName: "lock.shield.fill",
                            iconColor: .blue,
                            title: "Datenschutzrichtlinie",
                            subtitle: "Wie deine Daten verarbeitet werden",
                            url: URL(string: "https://aryamirsepasi.com/resumecraft/privacy")!
                        )
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .accessibilityLabel("Schließen")
                    }
                }
            }
            .sheet(isPresented: $showCloudKitDiagnostics) {
                CloudKitDiagnosticsView()
            }
            .task { await checkICloudStatus() }
            .task { await calculateScore() }
        }
    }

    private func checkICloudStatus() async {
        let container = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
        let status = try? await container.accountStatus()
        await MainActor.run {
            iCloudAccountStatus = status
        }
    }
    
    private var contentLanguageBinding: Binding<ResumeLanguage> {
        Binding(
            get: { resumeModel.resume.contentLanguage },
            set: { newValue in
                resumeModel.resume.contentLanguage = newValue
                try? resumeModel.save()
            }
        )
    }

    private var outputLanguageBinding: Binding<ResumeLanguage> {
        Binding(
            get: { resumeModel.resume.outputLanguage },
            set: { newValue in
                resumeModel.resume.outputLanguage = newValue
                try? resumeModel.save()
            }
        )
    }

    @MainActor
    private func calculateScore() async {
        let score = ResumeScoringEngine.calculate(for: resumeModel.resume)
        withAnimation {
            resumeScore = score
        }
    }
}

// Resume Score Row Content
private struct ResumeScoreRowContent: View {
    let score: ResumeScore
    
    var body: some View {
        HStack(spacing: 16) {
            // Circular score indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score.overallScore) / 100)
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(score.overallScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(gradeColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Lebenslaufbewertung")
                        .font(.headline)
                    
                    Text(score.grade.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(gradeColor)
                        .clipShape(Capsule())
                }
                
                Text(score.grade.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var gradeColor: Color {
        switch score.grade {
        case .a: return .green
        case .b: return .blue
        case .c: return .yellow
        case .d: return .orange
        case .f: return .red
        }
    }
}

// Unchanged
struct AboutLinkRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.accentColor)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square").foregroundColor(.gray)
            }
            .padding(.vertical, 12)
        }
    }
}
