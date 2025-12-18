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
                            Text("Analyzing resume...")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Resume Health")
                        .textCase(.uppercase)
                        .font(.caption)
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
                                Text("Smart Suggestions")
                                    .font(.subheadline.weight(.medium))
                                Text("AI-powered improvement tips")
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
                                Text("Version History")
                                    .font(.subheadline.weight(.medium))
                                Text("Track changes over time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Tools")
                        .textCase(.uppercase)
                        .font(.caption)
                }
                
                // On-device AI (Foundation Models) status
                Section("On-device AI") {
                    if #available(iOS 26, *) {
                        let availability = SystemLanguageModel.default.availability

                        HStack {
                            switch availability {
                            case .available:
                                Label("Apple Intelligence: Enabled", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                            case .unavailable(let reason):
                                Label("Apple Intelligence: Unavailable", systemImage: "xmark.octagon.fill")
                                    .foregroundStyle(.red)
                                Spacer()
                                Button("Open Settings") {
                                    openAppSettings()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Open Settings to enable Apple Intelligence")
                                .help("Reason: \(String(describing: reason))")
                            }
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Privacy & processing")
                                .font(.callout).bold()
                            Text("ResumeCraft uses the on-device foundation language model to review your résumé. Nothing leaves your device.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    } else {
                        Label("Requires iOS 26 or later", systemImage: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                }

                // iCloud Status
                Section("iCloud Status") {
                    HStack {
                        Image(systemName: persistenceStatus.isCloudKitEnabled ? "icloud.fill" : "externaldrive.fill")
                            .foregroundStyle(persistenceStatus.isCloudKitEnabled ? .blue : .orange)
                        let backendLabel: String = {
                            switch persistenceStatus.backend {
                            case .cloudKit:
                                return "Sync enabled"
                            case .local:
                                return "Local-only (sync disabled)"
                            case .inMemory:
                                return "In-memory (not saved)"
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
                    Text("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let error = persistenceStatus.cloudKitInitializationError {
                        Text("iCloud init error: \(error)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let error = persistenceStatus.localInitializationError {
                        Text("Local store error: \(error)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let status = iCloudAccountStatus {
                        HStack {
                            switch status {
                            case .available:
                                Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                Text("Connected to iCloud")
                            case .noAccount:
                                Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                                Text("Not signed in to iCloud (local-only mode)")
                            case .restricted:
                                Image(systemName: "xmark.octagon.fill")
                                .foregroundColor(.red)
                                Text("iCloud restricted (local-only mode)")
                            case .couldNotDetermine:
                                Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                                Text("Could not determine iCloud status")
                            case .temporarilyUnavailable:
                                Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                Text("iCloud temporarily unavailable")
                            @unknown default:
                                Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                                Text("Unknown iCloud status")
                            }
                            
                            Spacer()
                            
                            if status == .noAccount || status == .restricted {
                                Button("Open Settings") {
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
                            Text("Checking iCloud…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Text("Tip: CloudKit doesn’t sync between Debug/TestFlight/App Store builds (different environments). Make sure both devices run the same build channel.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // App info
                Section {
                    HStack {
                        Image("IconPreview")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(radius: 4)
                            .accessibilityLabel("App Icon")
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
                            title: "App Website",
                            subtitle: "Arya Mirsepasi",
                            url: URL(string: "https://aryamirsepasi.com/resumecraft")!
                        )
                        Divider()
                        AboutLinkRow(
                            iconName: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "Having Issues?",
                            subtitle: "Submit a new issue on the support page!",
                            url: URL(string: "https://aryamirsepasi.com/support")!
                        )
                        Divider()
                        AboutLinkRow(
                            iconName: "lock.shield.fill",
                            iconColor: .blue,
                            title: "Privacy Policy",
                            subtitle: "How your data is handled",
                            url: URL(string: "https://aryamirsepasi.com/resumecraft/privacy")!
                        )
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .accessibilityLabel("Close")
                    }
                }
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
                    Text("Resume Score")
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
