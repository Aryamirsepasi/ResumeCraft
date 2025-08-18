import SwiftUI
import CloudKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(OpenRouterSettings.self) private var openRouterSettings
    @Environment(OpenRouterProvider.self) private var openRouterProvider
    
    @State private var isICloudAvailable: Bool? = nil
    
    var body: some View {
        NavigationStack {
            List {
                // iCloud Status Section
                Section("iCloud Status") {
                    HStack {
                        Image(systemName: isICloudAvailable == true ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundColor(isICloudAvailable == true ? .green : .red)
                        Text(
                            isICloudAvailable == true
                            ? "Connected to iCloud"
                            : "Not Connected to iCloud"
                        )
                        .font(.body)
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
                
                Section {
                    HStack {
                        Image("IconPreview")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .shadow(radius: 4)
                            .accessibilityLabel("App Icon")
                        VStack(alignment: .leading) {
                            Text("ResumeCraft")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("© 2025 Arya Mirsepasi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("OpenRouter") {
                    TextField(
                        "API Key",
                        text: Binding(
                            get: { openRouterSettings.apiKey },
                            set: { openRouterSettings.apiKey = $0 }
                        )
                    )
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .privacySensitive(true)
                    
                    TextField(
                        "Model",
                        text: Binding(
                            get: { openRouterSettings.model },
                            set: { openRouterSettings.model = $0 }
                        )
                    )
                    .textInputAutocapitalization(.never)
                    .textContentType(.none)
                    
                    Text(
                        "Example models: openai/gpt-4o-mini, openai/gpt-4.1-mini, " +
                        "anthropic/claude-3.5-sonnet"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
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
            .onChange(of: openRouterSettings.apiKey) { _, _ in
                openRouterProvider.updateConfig(openRouterSettings.config)
            }
            .onChange(of: openRouterSettings.model) { _, _ in
                openRouterProvider.updateConfig(openRouterSettings.config)
            }
            .task {
                await checkICloudStatus()
            }
        }
    }
    
    private func checkICloudStatus() async {
        let container = CKContainer(
            identifier: "iCloud.com.aryamirsepasi.ResumeCraft"
        )
        let status = try? await container.accountStatus()
        await MainActor.run {
            isICloudAvailable = (status == .available)
        }
    }
}


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
          Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Image(systemName: "arrow.up.right.square")
          .foregroundColor(.gray)
      }
      .padding(.vertical, 12)
    }
  }
}
