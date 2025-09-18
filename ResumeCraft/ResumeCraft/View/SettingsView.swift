import SwiftUI
import CloudKit
import FoundationModels   // iOS 26+

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FoundationModelProvider.self) private var fmProvider

    @State private var isICloudAvailable: Bool? = nil

    var body: some View {
        NavigationStack {
            List {
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
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
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
                        Image(systemName: isICloudAvailable == true ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundColor(isICloudAvailable == true ? .green : .red)
                        Text(isICloudAvailable == true ? "Connected to iCloud" : "Not Connected to iCloud")
                        Spacer()
                        if isICloudAvailable == false {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
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
        }
    }

    private func checkICloudStatus() async {
        let container = CKContainer(identifier: "iCloud.com.aryamirsepasi.ResumeCraft")
        let status = try? await container.accountStatus()
        await MainActor.run {
            isICloudAvailable = (status == .available)
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
