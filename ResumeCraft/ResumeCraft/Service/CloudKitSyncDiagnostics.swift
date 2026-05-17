//
//  CloudKitSyncDiagnostics.swift
//  ResumeCraft
//
//  Diagnostics to help identify CloudKit sync issues
//

import SwiftUI
import SwiftData
import CloudKit

@MainActor
@Observable
class CloudKitSyncDiagnostics {
    struct DiagnosticMessage: Identifiable {
        enum Status {
            case success
            case warning
            case error
            case info
        }

        let id = UUID()
        let text: String
        let status: Status
    }

    var diagnosticMessages: [DiagnosticMessage] = []
    var isChecking = false

    func runDiagnostics(modelContext: ModelContext) async {
        isChecking = true
        diagnosticMessages.removeAll()

        await checkICloudAccountStatus()
        await checkContainerAccess()
        checkModelContainerSetup()
        await checkSyncStatus()

        isChecking = false
    }

    private func append(_ key: String.LocalizationValue, status: DiagnosticMessage.Status = .info) {
        diagnosticMessages.append(DiagnosticMessage(text: String(localized: key), status: status))
    }

    private func appendFormatted(
        _ key: String.LocalizationValue,
        status: DiagnosticMessage.Status = .info,
        _ args: CVarArg...
    ) {
        let template = String(localized: key)
        diagnosticMessages.append(
            DiagnosticMessage(text: String(format: template, arguments: args), status: status)
        )
    }

    private func checkICloudAccountStatus() async {
        do {
            let container = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
            let status = try await container.accountStatus()

            switch status {
            case .available:
                append("cloudkit.diag.account.available", status: .success)
            case .noAccount:
                append("cloudkit.diag.account.noAccount", status: .warning)
            case .restricted:
                append("cloudkit.diag.account.restricted", status: .warning)
            case .couldNotDetermine:
                append("cloudkit.diag.account.couldNotDetermine", status: .warning)
            case .temporarilyUnavailable:
                append("cloudkit.diag.account.temporarilyUnavailable", status: .warning)
            @unknown default:
                append("cloudkit.diag.account.unknown", status: .warning)
            }
        } catch {
            appendFormatted("cloudkit.diag.account.error", status: .error, error.localizedDescription)
        }
    }

    private func checkContainerAccess() async {
        do {
            let container = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
            let database = container.privateCloudDatabase

            let query = CKQuery(recordType: "CD_Resume", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            _ = try await database.records(matching: query, resultsLimit: 1)
            append("cloudkit.diag.container.ok", status: .success)
        } catch let error as CKError {
            switch error.code {
            case .networkUnavailable, .networkFailure:
                appendFormatted("cloudkit.diag.container.network", status: .warning, error.localizedDescription)
            case .notAuthenticated:
                append("cloudkit.diag.container.notAuthenticated", status: .warning)
            case .permissionFailure:
                append("cloudkit.diag.container.permission", status: .error)
            default:
                appendFormatted("cloudkit.diag.container.other", status: .error, error.localizedDescription)
            }
        } catch {
            appendFormatted("cloudkit.diag.container.other", status: .error, error.localizedDescription)
        }
    }

    private func checkModelContainerSetup() {
        appendFormatted("cloudkit.diag.modelContainer", CloudKitConfiguration.containerIdentifier)
        appendFormatted("cloudkit.diag.bundleId", Bundle.main.bundleIdentifier ?? "unknown")

        #if DEBUG
        append("cloudkit.diag.buildConfig.debug")
        #else
        append("cloudkit.diag.buildConfig.release")
        #endif

        append("cloudkit.diag.envWarning")
    }

    private func checkSyncStatus() async {
        append("cloudkit.diag.syncInfo")
        append("cloudkit.diag.syncTip")
    }
}

// Helper view to display diagnostics
struct CloudKitDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var diagnostics = CloudKitSyncDiagnostics()

    var body: some View {
        NavigationStack {
            List {
                if diagnostics.isChecking {
                    Section {
                        HStack {
                            ProgressView()
                            Text("cloudkit.diag.running")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if diagnostics.diagnosticMessages.isEmpty {
                    Section {
                        Text("cloudkit.diag.tapPrompt")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("cloudkit.diag.results") {
                        ForEach(diagnostics.diagnosticMessages) { message in
                            Text(message.text)
                                .font(.footnote)
                                .foregroundStyle(messageColor(for: message.status))
                        }
                    }

                    Section("cloudkit.diag.commonFixes") {
                        VStack(alignment: .leading, spacing: 12) {
                            DiagnosticTip(
                                icon: "person.fill.checkmark",
                                title: String(localized: "cloudkit.tip.signIn.title"),
                                description: String(localized: "cloudkit.tip.signIn.body")
                            )

                            DiagnosticTip(
                                icon: "arrow.triangle.2.circlepath",
                                title: String(localized: "cloudkit.tip.iCloudDrive.title"),
                                description: String(localized: "cloudkit.tip.iCloudDrive.body")
                            )

                            DiagnosticTip(
                                icon: "wifi",
                                title: String(localized: "cloudkit.tip.network.title"),
                                description: String(localized: "cloudkit.tip.network.body")
                            )

                            DiagnosticTip(
                                icon: "hammer.fill",
                                title: String(localized: "cloudkit.tip.buildType.title"),
                                description: String(localized: "cloudkit.tip.buildType.body")
                            )

                            DiagnosticTip(
                                icon: "clock.arrow.circlepath",
                                title: String(localized: "cloudkit.tip.waitForSync.title"),
                                description: String(localized: "cloudkit.tip.waitForSync.body")
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("cloudkit.diag.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("cloudkit.diag.run") {
                        Task {
                            await diagnostics.runDiagnostics(modelContext: modelContext)
                        }
                    }
                    .disabled(diagnostics.isChecking)
                }
            }
        }
    }

    private func messageColor(for status: CloudKitSyncDiagnostics.DiagnosticMessage.Status) -> Color {
        switch status {
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .info:
            return .primary
        }
    }
}

struct DiagnosticTip: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
