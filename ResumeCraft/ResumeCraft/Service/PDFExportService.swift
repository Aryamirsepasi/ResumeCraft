//
//  PDFExportService.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//


import UIKit
import PDFKit

// MARK: - Export Error

enum PDFExportError: Error, LocalizedError {
    case resumeTooLong
    case exportFailed(String)
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .resumeTooLong:
            return String(localized: "export.error.tooLong")
        case .exportFailed(let reason):
            let template = String(localized: "export.error.failed")
            return String(format: template, reason)
        case .invalidFormat:
            return String(localized: "export.error.invalidFormat")
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    var format: ExportFormat = .pdf
    var fileName: String = "Lebenslauf"
    var includeMetadata: Bool = true
    var pageSize: PageSize = .a4
    var margins: Margins = .standard
    var outputLanguage: ResumeLanguage = .defaultOutput
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF"
        case text = "TXT"
        case markdown = "Markdown"
        case html = "HTML"

        var id: String { rawValue }

        /// User-facing format name; localized so e.g. .text reads as "Plain Text" / "Klartext".
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .text: return String(localized: "export.format.text.name")
            case .markdown: return "Markdown"
            case .html: return "HTML"
            }
        }

        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .text: return "txt"
            case .markdown: return "md"
            case .html: return "html"
            }
        }

        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .text: return "doc.text"
            case .markdown: return "doc.plaintext"
            case .html: return "globe"
            }
        }

        var description: String {
            switch self {
            case .pdf: return String(localized: "export.format.pdf.description")
            case .text: return String(localized: "export.format.text.description")
            case .markdown: return String(localized: "export.format.markdown.description")
            case .html: return String(localized: "export.format.html.description")
            }
        }
    }
    
    enum PageSize: String, CaseIterable, Identifiable {
        case a4 = "A4"
        case letter = "US Letter"
        
        var id: String { rawValue }
        
        var size: CGSize {
            switch self {
            case .a4: return CGSize(width: 595, height: 842)
            case .letter: return CGSize(width: 612, height: 792)
            }
        }
    }
    
    struct Margins {
        let top: CGFloat
        let bottom: CGFloat
        let left: CGFloat
        let right: CGFloat
        
        static let standard = Margins(top: 32, bottom: 32, left: 32, right: 32)
        static let narrow = Margins(top: 20, bottom: 20, left: 20, right: 20)
        static let wide = Margins(top: 48, bottom: 48, left: 48, right: 48)
    }
}

// MARK: - Export Result

struct ExportResult {
    let url: URL
    let format: ExportOptions.ExportFormat
    let fileSize: Int64
    let pageCount: Int?
    let exportDate: Date
    
    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - PDF Export Service

final class PDFExportService {
    
    // MARK: - Main Export Methods
    
    /// Export resume with specified options
    @MainActor
    static func export(resume: Resume, options: ExportOptions = ExportOptions()) throws -> ExportResult {
        switch options.format {
        case .pdf:
            return try exportPDF(resume: resume, options: options)
        case .text:
            return try exportPlainText(resume: resume, options: options)
        case .markdown:
            return try exportMarkdown(resume: resume, options: options)
        case .html:
            return try exportHTML(resume: resume, options: options)
        }
    }
    
    /// Legacy export method for backward compatibility
    @MainActor
    static func export(resume: Resume, fileName: String = "Lebenslauf.pdf") throws -> URL {
        var options = ExportOptions()
        options.fileName = fileName.replacingOccurrences(of: ".pdf", with: "")
        options.outputLanguage = resume.outputLanguage
        let result = try export(resume: resume, options: options)
        return result.url
    }
    
    // MARK: - PDF Export
    
    @MainActor
    private static func exportPDF(resume: Resume, options: ExportOptions) throws -> ExportResult {
        let attributedResume = ResumePDFFormatter.attributedString(
            for: resume,
            pageWidth: options.pageSize.size.width,
            language: options.outputLanguage
        )
        return try exportPDFFromAttributedString(attributedResume, options: options)
    }

    /// Generates raw PDF `Data` from a pre-built attributed string.
    /// Shared by both the in-app preview (PDFView) and the file export,
    /// guaranteeing pixel-perfect parity between the two.
    /// Safe to call from any thread — no SwiftData `@Model` access.
    static func pdfData(
        from attributedResume: NSAttributedString,
        options: ExportOptions
    ) throws -> Data {
        let pageSize = options.pageSize.size
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let margins = options.margins
        let textRect = CGRect(
            x: margins.left,
            y: margins.top,
            width: pageSize.width - margins.left - margins.right,
            height: pageSize.height - margins.top - margins.bottom
        )
        let maxPages = 2

        // Use NSLayoutManager to paginate the attributed string
        let textStorage = NSTextStorage(attributedString: attributedResume)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        var pageRanges: [NSRange] = []
        var pageStart = 0

        for _ in 0..<maxPages {
            let textContainer = NSTextContainer(size: textRect.size)
            layoutManager.addTextContainer(textContainer)
            let glyphRange = layoutManager.glyphRange(for: textContainer)
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            pageRanges.append(charRange)
            pageStart = charRange.location + charRange.length
            if pageStart >= attributedResume.length { break }
        }

        // If not all text fits in two pages, throw error
        if pageStart < attributedResume.length {
            throw PDFExportError.resumeTooLong
        }

        // Create PDF with metadata
        var documentInfo: [String: Any] = [:]
        if options.includeMetadata {
            let subject = String(localized: "resume.export.subject", locale: options.outputLanguage.locale)
            documentInfo = [
                kCGPDFContextTitle as String: options.fileName,
                kCGPDFContextCreator as String: "ResumeCraft",
                kCGPDFContextSubject as String: subject,
            ]
        }

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = documentInfo

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { ctx in
            for range in pageRanges {
                ctx.beginPage()
                let pageText = attributedResume.attributedSubstring(from: range)
                pageText.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            }
        }
    }

    /// Exports a PDF from a pre-built attributed string to a temporary file.
    /// Safe to call from a background thread — no SwiftData `@Model` access.
    static func exportPDFFromAttributedString(
        _ attributedResume: NSAttributedString,
        options: ExportOptions
    ) throws -> ExportResult {
        let data = try pdfData(from: attributedResume, options: options)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = sanitizeFileName(options.fileName) + ".pdf"
        let url = tempDir.appendingPathComponent(fileName)

        try data.write(to: url, options: .atomic)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        return ExportResult(
            url: url,
            format: .pdf,
            fileSize: fileSize,
            pageCount: nil,
            exportDate: Date()
        )
    }

    /// Exports pre-built text content to a file. Safe to call off main actor.
    static func exportPrebuiltText(
        _ text: String,
        options: ExportOptions
    ) throws -> ExportResult {
        let tempDir = FileManager.default.temporaryDirectory
        let ext = options.format.fileExtension
        let fileName = sanitizeFileName(options.fileName) + ".\(ext)"
        let url = tempDir.appendingPathComponent(fileName)

        try text.write(to: url, atomically: true, encoding: .utf8)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        return ExportResult(
            url: url,
            format: options.format,
            fileSize: fileSize,
            pageCount: nil,
            exportDate: Date()
        )
    }

    /// Generate markdown on main actor (accesses @Model). Call before background export.
    @MainActor
    static func generateMarkdownOnMainActor(for resume: Resume, language: ResumeLanguage) -> String {
        generateMarkdown(for: resume, language: language)
    }

    /// Generate HTML on main actor (accesses @Model). Call before background export.
    @MainActor
    static func generateHTMLOnMainActor(for resume: Resume, language: ResumeLanguage) -> String {
        generateHTML(for: resume, language: language)
    }
    
    // MARK: - Plain Text Export
    
    @MainActor
    private static func exportPlainText(resume: Resume, options: ExportOptions) throws -> ExportResult {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = sanitizeFileName(options.fileName) + ".txt"
        let url = tempDir.appendingPathComponent(fileName)
        
        let text = ResumeTextFormatter.plainText(for: resume, language: options.outputLanguage)
        
        try text.write(to: url, atomically: true, encoding: .utf8)
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        
        return ExportResult(
            url: url,
            format: .text,
            fileSize: fileSize,
            pageCount: nil,
            exportDate: Date()
        )
    }
    
    // MARK: - Markdown Export
    
    @MainActor
    private static func exportMarkdown(resume: Resume, options: ExportOptions) throws -> ExportResult {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = sanitizeFileName(options.fileName) + ".md"
        let url = tempDir.appendingPathComponent(fileName)
        
        let markdown = generateMarkdown(for: resume, language: options.outputLanguage)
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        
        return ExportResult(
            url: url,
            format: .markdown,
            fileSize: fileSize,
            pageCount: nil,
            exportDate: Date()
        )
    }
    
    // MARK: - HTML Export
    
    @MainActor
    private static func exportHTML(resume: Resume, options: ExportOptions) throws -> ExportResult {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = sanitizeFileName(options.fileName) + ".html"
        let url = tempDir.appendingPathComponent(fileName)
        
        let html = generateHTML(for: resume, language: options.outputLanguage)
        
        try html.write(to: url, atomically: true, encoding: .utf8)
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        
        return ExportResult(
            url: url,
            format: .html,
            fileSize: fileSize,
            pageCount: nil,
            exportDate: Date()
        )
    }
    
    // MARK: - Markdown Generator
    
    private static func generateMarkdown(for resume: Resume, language: ResumeLanguage) -> String {
        var md = ""
        let fallback = language.fallback
        let atWord = String(localized: "resume.label.at", locale: language.locale)
        let technologiesLabel = String(localized: "resume.label.technologies", locale: language.locale)
        let gradeLabel = String(localized: "resume.label.grade", locale: language.locale)
        
        // Header
        if let personal = resume.personal {
            md += "# \(personal.firstName) \(personal.lastName)\n\n"
            
            var contact: [String] = []
            if !personal.email.isEmpty { contact.append("📧 \(personal.email)") }
            if !personal.phone.isEmpty { contact.append("📱 \(personal.phone)") }
            let address = personal.address(for: language, fallback: fallback)
            if !address.isEmpty { contact.append("📍 \(address)") }
            
            if !contact.isEmpty {
                md += contact.joined(separator: " | ") + "\n\n"
            }
            
            var links: [String] = []
            if let linkedIn = personal.linkedIn, !linkedIn.isEmpty {
                links.append("[LinkedIn](\(linkedIn))")
            }
            if let github = personal.github, !github.isEmpty {
                links.append("[GitHub](\(github))")
            }
            if let website = personal.website, !website.isEmpty {
                links.append("[Website](\(website))")
            }
            
            if !links.isEmpty {
                md += links.joined(separator: " | ") + "\n\n"
            }
        }
        
        // Summary
        if let summary = resume.summary, summary.isVisible {
            let summaryText = summary.text(for: language, fallback: fallback)
            if !summaryText.isEmpty {
                md += "## \(ResumeSection.summary.title(for: language))\n\n"
                md += summaryText + "\n\n"
            }
        }
        
        // Skills
        let skills = (resume.skills ?? []).filter(\.isVisible)
        if !skills.isEmpty {
            md += "## \(ResumeSection.skills.title(for: language))\n\n"
            let grouped = Dictionary(grouping: skills) { $0.category(for: language, fallback: fallback) }
            for (category, categorySkills) in grouped.sorted(by: { $0.key < $1.key }) {
                if !category.isEmpty {
                    md += "**\(category):** "
                }
                md += categorySkills.map { $0.name(for: language, fallback: fallback) }.joined(separator: ", ") + "\n\n"
            }
        }
        
        // Experience
        let experiences = (resume.experiences ?? []).filter(\.isVisible).sorted { $0.orderIndex < $1.orderIndex }
        if !experiences.isEmpty {
            md += "## \(ResumeSection.experience.title(for: language))\n\n"
            for exp in experiences {
                let title = exp.title(for: language, fallback: fallback)
                let company = exp.company(for: language, fallback: fallback)
                let location = exp.location(for: language, fallback: fallback)
                let dateRange = formatDateRange(exp.startDate, exp.endDate, exp.isCurrent, language: language)
                let locationLine = location.isEmpty ? dateRange : "\(dateRange) | \(location)"
                md += "### \(title) \(atWord) \(company)\n"
                md += "*\(locationLine)*\n\n"
                
                let details = exp.details(for: language, fallback: fallback)
                let bullets = details.components(separatedBy: "\n").filter { !$0.isEmpty }
                for bullet in bullets {
                    md += "- \(bullet.trimmingCharacters(in: .whitespaces))\n"
                }
                md += "\n"
            }
        }
        
        // Projects
        let projects = (resume.projects ?? []).filter(\.isVisible).sorted { $0.orderIndex < $1.orderIndex }
        if !projects.isEmpty {
            md += "## \(ResumeSection.projects.title(for: language))\n\n"
            for proj in projects {
                let name = proj.name(for: language, fallback: fallback)
                let technologies = proj.technologies(for: language, fallback: fallback)
                let details = proj.details(for: language, fallback: fallback)
                md += "### \(name)\n"
                if !technologies.isEmpty {
                    md += "*\(technologiesLabel): \(technologies)*\n\n"
                }
                md += details + "\n"
                if let link = proj.link, !link.isEmpty {
                    md += "\n🔗 [\(link)](\(link))\n"
                }
                md += "\n"
            }
        }
        
        // Education
        let educations = (resume.educations ?? []).filter(\.isVisible).sorted { $0.orderIndex < $1.orderIndex }
        if !educations.isEmpty {
            md += "## \(ResumeSection.education.title(for: language))\n\n"
            for edu in educations {
                let degree = edu.degree(for: language, fallback: fallback)
                let field = edu.field(for: language, fallback: fallback)
                let school = edu.school(for: language, fallback: fallback)
                let grade = edu.grade(for: language, fallback: fallback)
                let dateRange = formatDateRange(edu.startDate, edu.endDate, false, language: language)
                let titleLine = field.isEmpty ? degree : "\(degree) in \(field)"
                md += "### \(titleLine)\n"
                md += "**\(school)** | *\(dateRange)*\n"
                if !grade.isEmpty {
                    md += "\(gradeLabel): \(grade)\n"
                }
                md += "\n"
            }
        }
        
        // Languages
        let languages = (resume.languages ?? []).filter(\.isVisible)
        if !languages.isEmpty {
            md += "## \(ResumeSection.languages.title(for: language))\n\n"
            md += languages.map {
                let name = $0.name(for: language, fallback: fallback)
                let proficiency = $0.proficiency(for: language, fallback: fallback)
                return "\(name) (\(proficiency))"
            }.joined(separator: " | ") + "\n"
        }

        let miscText = resume.miscellaneous(for: language, fallback: fallback)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !miscText.isEmpty {
            md += "\n## \(ResumeSection.miscellaneous.title(for: language))\n\n"
            md += miscText + "\n"
        }
        
        return md
    }
    
    // MARK: - HTML Generator
    
    private static func generateHTML(for resume: Resume, language: ResumeLanguage) -> String {
        let fallback = language.fallback
        let atWord = escapeHTML(String(localized: "resume.label.at", locale: language.locale))
        let technologiesLabel = escapeHTML(String(localized: "resume.label.technologies", locale: language.locale))
        let gradeLabel = escapeHTML(String(localized: "resume.label.grade", locale: language.locale))
        let titleLabel = escapeHTML(String(localized: "resume.export.subject", locale: language.locale))
        var html = """
        <!DOCTYPE html>
        <html lang="\(language.rawValue)">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(resume.personal?.firstName ?? "")) \(escapeHTML(resume.personal?.lastName ?? "")) - \(titleLabel)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 800px; margin: 0 auto; padding: 40px 20px; }
                h1 { font-size: 2em; margin-bottom: 0.5em; color: #1a1a1a; }
                h2 { font-size: 1.3em; margin: 1.5em 0 0.5em; padding-bottom: 0.3em; border-bottom: 2px solid #007AFF; color: #1a1a1a; }
                h3 { font-size: 1.1em; margin: 1em 0 0.3em; }
                .contact { color: #666; margin-bottom: 1em; }
                .contact a { color: #007AFF; text-decoration: none; }
                .summary { margin: 1em 0; }
                .skills { display: flex; flex-wrap: wrap; gap: 0.5em; }
                .skill { background: #f0f0f0; padding: 0.3em 0.8em; border-radius: 15px; font-size: 0.9em; }
                .experience-item, .project-item, .education-item { margin: 1em 0; padding: 1em; background: #f9f9f9; border-radius: 8px; }
                .date { color: #666; font-size: 0.9em; }
                ul { padding-left: 1.5em; margin: 0.5em 0; }
                li { margin: 0.3em 0; }
                .tech { color: #007AFF; font-size: 0.9em; }
            </style>
        </head>
        <body>
        """
        
        // Header
        if let personal = resume.personal {
            let firstName = escapeHTML(personal.firstName)
            let lastName = escapeHTML(personal.lastName)
            html += "<h1>\(firstName) \(lastName)</h1>\n"
            html += "<div class=\"contact\">\n"
            
            var contact: [String] = []
            if !personal.email.isEmpty {
                let email = escapeHTML(personal.email)
                contact.append("<a href=\"mailto:\(email)\">\(email)</a>")
            }
            if !personal.phone.isEmpty { contact.append(escapeHTML(personal.phone)) }
            let address = personal.address(for: language, fallback: fallback)
            if !address.isEmpty { contact.append(escapeHTML(address)) }
            
            html += contact.joined(separator: " • ") + "\n"
            
            var links: [String] = []
            if let linkedIn = personal.linkedIn, !linkedIn.isEmpty {
                links.append("<a href=\"\(escapeHTML(linkedIn))\">LinkedIn</a>")
            }
            if let github = personal.github, !github.isEmpty {
                links.append("<a href=\"\(escapeHTML(github))\">GitHub</a>")
            }
            if let website = personal.website, !website.isEmpty {
                links.append("<a href=\"\(escapeHTML(website))\">Website</a>")
            }
            
            if !links.isEmpty {
                html += "<br>" + links.joined(separator: " • ") + "\n"
            }
            html += "</div>\n"
        }
        
        // Summary
        if let summary = resume.summary, summary.isVisible {
            let summaryText = summary.text(for: language, fallback: fallback)
            if !summaryText.isEmpty {
                html += "<h2>\(escapeHTML(ResumeSection.summary.title(for: language)))</h2>\n"
                html += "<p class=\"summary\">\(escapeHTML(summaryText))</p>\n"
            }
        }
        
        // Skills
        let skills = (resume.skills ?? []).filter(\.isVisible)
        if !skills.isEmpty {
            html += "<h2>\(escapeHTML(ResumeSection.skills.title(for: language)))</h2>\n<div class=\"skills\">\n"
            for skill in skills {
                let name = escapeHTML(skill.name(for: language, fallback: fallback))
                html += "<span class=\"skill\">\(name)</span>\n"
            }
            html += "</div>\n"
        }
        
        // Experience
        let experiences = (resume.experiences ?? []).filter(\.isVisible).sorted { $0.orderIndex < $1.orderIndex }
        if !experiences.isEmpty {
            html += "<h2>\(escapeHTML(ResumeSection.experience.title(for: language)))</h2>\n"
            for exp in experiences {
                let title = escapeHTML(exp.title(for: language, fallback: fallback))
                let company = escapeHTML(exp.company(for: language, fallback: fallback))
                let location = escapeHTML(exp.location(for: language, fallback: fallback))
                let dateRange = escapeHTML(formatDateRange(exp.startDate, exp.endDate, exp.isCurrent, language: language))
                let locationLine = location.isEmpty ? dateRange : "\(dateRange) • \(location)"
                html += "<div class=\"experience-item\">\n"
                html += "<h3>\(title) \(atWord) \(company)</h3>\n"
                html += "<p class=\"date\">\(locationLine)</p>\n"
                
                let details = exp.details(for: language, fallback: fallback)
                let bullets = details.components(separatedBy: "\n").filter { !$0.isEmpty }
                if !bullets.isEmpty {
                    html += "<ul>\n"
                    for bullet in bullets {
                        html += "<li>\(escapeHTML(bullet.trimmingCharacters(in: .whitespaces)))</li>\n"
                    }
                    html += "</ul>\n"
                }
                html += "</div>\n"
            }
        }
        
        // Projects
        let projects = (resume.projects ?? []).filter(\.isVisible).sorted { $0.orderIndex < $1.orderIndex }
        if !projects.isEmpty {
            html += "<h2>\(escapeHTML(ResumeSection.projects.title(for: language)))</h2>\n"
            for proj in projects {
                let name = escapeHTML(proj.name(for: language, fallback: fallback))
                let technologies = escapeHTML(proj.technologies(for: language, fallback: fallback))
                let details = escapeHTML(proj.details(for: language, fallback: fallback))
                html += "<div class=\"project-item\">\n"
                html += "<h3>\(name)</h3>\n"
                if !technologies.isEmpty {
                    html += "<p class=\"tech\">\(technologiesLabel): \(technologies)</p>\n"
                }
                html += "<p>\(details)</p>\n"
                if let link = proj.link, !link.isEmpty {
                    let escapedLink = escapeHTML(link)
                    html += "<p><a href=\"\(escapedLink)\">\(escapedLink)</a></p>\n"
                }
                html += "</div>\n"
            }
        }
        
        // Education
        let educations = (resume.educations ?? []).filter(\.isVisible).sorted { $0.orderIndex < $1.orderIndex }
        if !educations.isEmpty {
            html += "<h2>\(escapeHTML(ResumeSection.education.title(for: language)))</h2>\n"
            for edu in educations {
                let degree = escapeHTML(edu.degree(for: language, fallback: fallback))
                let field = escapeHTML(edu.field(for: language, fallback: fallback))
                let school = escapeHTML(edu.school(for: language, fallback: fallback))
                let grade = escapeHTML(edu.grade(for: language, fallback: fallback))
                let dateRange = escapeHTML(formatDateRange(edu.startDate, edu.endDate, false, language: language))
                let titleLine = field.isEmpty ? degree : "\(degree) in \(field)"
                html += "<div class=\"education-item\">\n"
                html += "<h3>\(titleLine)</h3>\n"
                html += "<p><strong>\(school)</strong></p>\n"
                html += "<p class=\"date\">\(dateRange)</p>\n"
                if !grade.isEmpty {
                    html += "<p>\(gradeLabel): \(grade)</p>\n"
                }
                html += "</div>\n"
            }
        }
        
        // Languages
        let languages = (resume.languages ?? []).filter(\.isVisible)
        if !languages.isEmpty {
            html += "<h2>\(escapeHTML(ResumeSection.languages.title(for: language)))</h2>\n<p>"
            html += languages.map {
                let name = escapeHTML($0.name(for: language, fallback: fallback))
                let proficiency = escapeHTML($0.proficiency(for: language, fallback: fallback))
                return "\(name) (\(proficiency))"
            }.joined(separator: " • ")
            html += "</p>\n"
        }

        let miscText = resume.miscellaneous(for: language, fallback: fallback)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !miscText.isEmpty {
            html += "<h2>\(escapeHTML(ResumeSection.miscellaneous.title(for: language)))</h2>\n"
            html += "<p>\(escapeHTML(miscText))</p>\n"
        }
        
        html += "</body>\n</html>"
        
        return html
    }
    
    // MARK: - Helpers

    /// Escapes special HTML characters in user-provided content
    /// to prevent broken output or injection.
    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func sanitizeFileName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidChars).joined(separator: "_")
    }
    
    private static func formatDateRange(
        _ start: Date,
        _ end: Date?,
        _ isCurrent: Bool,
        language: ResumeLanguage
    ) -> String {
        let formatter = DateFormatter.resumeMonthYear(for: language)
        guard start != .distantPast else { return isCurrent ? String(localized: "resume.label.today", locale: language.locale) : "-" }
        let startStr = formatter.string(from: start)
        let present = String(localized: "resume.label.today", locale: language.locale)
        
        if isCurrent {
            return "\(startStr) – \(present)"
        } else if let end = end {
            return "\(startStr) – \(formatter.string(from: end))"
        } else {
            return startStr
        }
    }
}
