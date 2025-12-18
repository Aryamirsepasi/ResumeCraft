//
//  ExportOptionsView.swift
//  ResumeCraft
//
//  Enhanced export options UI for multiple formats
//

import SwiftUI

struct ExportOptionsView: View {
    let resume: Resume
    @Environment(\.dismiss) private var dismiss
    
    @State private var options = ExportOptions()
    @State private var isExporting = false
    @State private var exportResult: ExportResult?
    @State private var exportError: String?
    @State private var showShareSheet = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Format Selection
                Section {
                    ForEach(ExportOptions.ExportFormat.allCases) { format in
                        FormatOptionRow(
                            format: format,
                            isSelected: options.format == format,
                            onSelect: { options.format = format }
                        )
                    }
                } header: {
                    Text("Export Format")
                } footer: {
                    Text(options.format.description)
                }
                
                // File Name
                Section("File Name") {
                    HStack {
                        TextField("Resume", text: $options.fileName)
                            .textInputAutocapitalization(.words)
                        
                        Text(".\(options.format.fileExtension)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // PDF Options (only show for PDF format)
                if options.format == .pdf {
                    Section("Page Settings") {
                        Picker("Page Size", selection: $options.pageSize) {
                            ForEach(ExportOptions.PageSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        
                        Picker("Margins", selection: Binding(
                            get: { marginsSelection },
                            set: { setMargins($0) }
                        )) {
                            Text("Standard").tag("standard")
                            Text("Narrow").tag("narrow")
                            Text("Wide").tag("wide")
                        }
                    }
                    
                    Section {
                        Toggle("Include PDF Metadata", isOn: $options.includeMetadata)
                    } footer: {
                        Text("Adds author name, title, and creation date to the PDF file properties.")
                    }
                }
                
                // Export Preview
                Section {
                    ExportPreviewCard(resume: resume, format: options.format)
                } header: {
                    Text("Preview")
                }
                
                // Export Button
                Section {
                    Button {
                        performExport()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Exporting...")
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export \(options.format.rawValue)")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .padding(.vertical, 4)
                    }
                    .disabled(isExporting || options.fileName.isEmpty)
                }
            }
            .navigationTitle("Export Resume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let result = exportResult {
                    ShareSheetView(url: result.url, result: result)
                }
            }
            .alert("Export Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportError ?? "An unknown error occurred.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var marginsSelection: String {
        if options.margins.top == ExportOptions.Margins.narrow.top { return "narrow" }
        if options.margins.top == ExportOptions.Margins.wide.top { return "wide" }
        return "standard"
    }
    
    private func setMargins(_ selection: String) {
        switch selection {
        case "narrow": options.margins = .narrow
        case "wide": options.margins = .wide
        default: options.margins = .standard
        }
    }
    
    private func performExport() {
        isExporting = true
        exportError = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try PDFExportService.export(resume: resume, options: options)
                
                DispatchQueue.main.async {
                    exportResult = result
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    exportError = error.localizedDescription
                    showError = true
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Format Option Row

private struct FormatOptionRow: View {
    let format: ExportOptions.ExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: format.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .blue : .gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(".\(format.fileExtension)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Export Preview Card

private struct ExportPreviewCard: View {
    let resume: Resume
    let format: ExportOptions.ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: format.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                Text("\(resume.personal?.firstName ?? "") \(resume.personal?.lastName ?? "")")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 24) {
                StatItem(
                    icon: "briefcase.fill",
                    value: "\((resume.experiences ?? []).filter(\.isVisible).count)",
                    label: "Jobs"
                )
                StatItem(
                    icon: "star.fill",
                    value: "\((resume.skills ?? []).filter(\.isVisible).count)",
                    label: "Skills"
                )
                StatItem(
                    icon: "text.word.spacing",
                    value: "\(wordCount)",
                    label: "Words"
                )
            }
            
            // Format-specific info
            Text(formatInfo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var wordCount: Int {
        ResumeTextFormatter.plainText(for: resume).split(separator: " ").count
    }
    
    private var formatInfo: String {
        switch format {
        case .pdf:
            return "PDF format preserves formatting and is ideal for job applications."
        case .text:
            return "Plain text format is ATS-friendly and works with any system."
        case .markdown:
            return "Markdown is great for version control and easy editing."
        case .html:
            return "HTML format can be viewed in any web browser."
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Sheet View

private struct ShareSheetView: View {
    let url: URL
    let result: ExportResult
    
    @Environment(\.dismiss) private var dismiss
    @State private var showActivitySheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                }
                .padding(.top, 24)
                
                // Title
                Text("Export Successful!")
                    .font(.title2.bold())
                
                // Details card
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Format", value: result.format.rawValue)
                    DetailRow(label: "File Size", value: result.fileSizeFormatted)
                    if let pages = result.pageCount {
                        DetailRow(label: "Pages", value: "\(pages)")
                    }
                    DetailRow(label: "Created", value: result.exportDate.formatted(date: .abbreviated, time: .shortened))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                Spacer()
                
                // Share button
                Button {
                    showActivitySheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Export Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showActivitySheet) {
                ShareSheet(item: url)
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
