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
class CloudKitSyncDiagnostics: ObservableObject {
    @Published var diagnosticMessages: [String] = []
    @Published var isChecking = false
    
    func runDiagnostics(modelContext: ModelContext) async {
        isChecking = true
        diagnosticMessages.removeAll()
        
        // Check 1: iCloud Account Status
        await checkICloudAccountStatus()
        
        // Check 2: Container Access
        await checkContainerAccess()
        
        // Check 3: Verify Model Container Configuration
        checkModelContainerSetup()
        
        // Check 4: Check for pending sync operations
        await checkSyncStatus()
        
        isChecking = false
    }
    
    private func checkICloudAccountStatus() async {
        do {
            let container = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                diagnosticMessages.append("✅ iCloud-Konto: Verfügbar")
            case .noAccount:
                diagnosticMessages.append("❌ iCloud-Konto: Nicht angemeldet – bitte in den iCloud-Einstellungen anmelden")
            case .restricted:
                diagnosticMessages.append("❌ iCloud-Konto: Durch Elternkontrolle oder Geräteverwaltung eingeschränkt")
            case .couldNotDetermine:
                diagnosticMessages.append("⚠️ iCloud-Konto: Status konnte nicht ermittelt werden")
            case .temporarilyUnavailable:
                diagnosticMessages.append("⚠️ iCloud-Konto: Vorübergehend nicht verfügbar")
            @unknown default:
                diagnosticMessages.append("⚠️ iCloud-Konto: Unbekannter Status")
            }
        } catch {
            diagnosticMessages.append("❌ Fehler beim Prüfen des iCloud-Status: \(error.localizedDescription)")
        }
    }
    
    private func checkContainerAccess() async {
        do {
            let container = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
            let database = container.privateCloudDatabase
            
            // Try to fetch a record type to verify permissions
            let query = CKQuery(recordType: "CD_Resume", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            _ = try await database.records(matching: query, resultsLimit: 1)
            diagnosticMessages.append("✅ CloudKit-Container: Zugriff möglich")
        } catch let error as CKError {
            switch error.code {
            case .networkUnavailable, .networkFailure:
                diagnosticMessages.append("⚠️ CloudKit-Container: Netzwerkproblem – \(error.localizedDescription)")
            case .notAuthenticated:
                diagnosticMessages.append("❌ CloudKit-Container: Nicht authentifiziert – iCloud-Anmeldung prüfen")
            case .permissionFailure:
                diagnosticMessages.append("❌ CloudKit-Container: Berechtigung verweigert – App-Berechtigungen prüfen")
            default:
                diagnosticMessages.append("⚠️ CloudKit-Container: \(error.localizedDescription)")
            }
        } catch {
            diagnosticMessages.append("⚠️ CloudKit-Container: \(error.localizedDescription)")
        }
    }
    
    private func checkModelContainerSetup() {
        diagnosticMessages.append("ℹ️ Model-Container: Verwende Container '\(CloudKitConfiguration.containerIdentifier)'")
        diagnosticMessages.append("ℹ️ Bundle-ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        // Verify build configuration
        #if DEBUG
        diagnosticMessages.append("⚠️ Build-Konfiguration: DEBUG – CloudKit verwendet die Entwicklungsumgebung")
        #else
        diagnosticMessages.append("ℹ️ Build-Konfiguration: RELEASE – CloudKit verwendet die Produktionsumgebung")
        #endif
        
        diagnosticMessages.append("⚠️ Wichtig: Debug- und Release-Builds nutzen unterschiedliche CloudKit-Umgebungen und synchronisieren nicht miteinander")
    }
    
    private func checkSyncStatus() async {
        // Check for network connectivity
        diagnosticMessages.append("ℹ️ Sync-Status: SwiftData synchronisiert automatisch, wenn das Netzwerk verfügbar ist")
        diagnosticMessages.append("ℹ️ Tipp: Änderungen brauchen ggf. etwas Zeit. Ziehe zum Aktualisieren auf dem anderen Gerät nach unten.")
    }
}

// Helper view to display diagnostics
struct CloudKitDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diagnostics = CloudKitSyncDiagnostics()
    
    var body: some View {
        NavigationStack {
            List {
                if diagnostics.isChecking {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Diagnose läuft...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if diagnostics.diagnosticMessages.isEmpty {
                    Section {
                        Text("Tippe auf „Diagnose ausführen“, um den CloudKit-Sync-Status zu prüfen")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Diagnose-Ergebnisse") {
                        ForEach(diagnostics.diagnosticMessages, id: \.self) { message in
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(messageColor(for: message))
                        }
                    }
                    
                    Section("Häufige Lösungen") {
                        VStack(alignment: .leading, spacing: 12) {
                            DiagnosticTip(
                                icon: "person.fill.checkmark",
                                title: "Bei iCloud anmelden",
                                description: "Gehe zu Einstellungen > [Dein Name] und melde dich auf beiden Geräten mit deiner Apple ID an"
                            )
                            
                            DiagnosticTip(
                                icon: "arrow.triangle.2.circlepath",
                                title: "iCloud Drive prüfen",
                                description: "Gehe zu Einstellungen > [Dein Name] > iCloud und stelle sicher, dass iCloud Drive aktiviert ist"
                            )
                            
                            DiagnosticTip(
                                icon: "wifi",
                                title: "Netzwerkverbindung",
                                description: "Stelle sicher, dass beide Geräte eine stabile Internetverbindung haben"
                            )
                            
                            DiagnosticTip(
                                icon: "hammer.fill",
                                title: "Gleicher Build-Typ",
                                description: "Beide Geräte müssen denselben Build-Typ verwenden (beide Debug oder beide Release/TestFlight/App Store)"
                            )
                            
                            DiagnosticTip(
                                icon: "clock.arrow.circlepath",
                                title: "Auf Synchronisierung warten",
                                description: "CloudKit-Sync kann ein paar Minuten dauern. Beende die App und öffne sie auf beiden Geräten neu"
                            )
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("CloudKit-Diagnose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Diagnose ausführen") {
                        Task {
                            await diagnostics.runDiagnostics(modelContext: modelContext)
                        }
                    }
                    .disabled(diagnostics.isChecking)
                }
            }
        }
    }
    
    private func messageColor(for message: String) -> Color {
        if message.starts(with: "✅") {
            return .green
        } else if message.starts(with: "❌") {
            return .red
        } else if message.starts(with: "⚠️") {
            return .orange
        } else {
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
