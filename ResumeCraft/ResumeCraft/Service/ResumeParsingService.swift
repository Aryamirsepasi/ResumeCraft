//
//  ResumeParsingService.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import NaturalLanguage
import PDFKit
import Vision

struct ContactInfo {
    var name: String?
    var email: String?
    var phone: String?
    var location: String?
    var linkedIn: String?
    var website: String?
    var github: String?
}

struct JobExperience {
    var title: String
    var company: String
    var startDate: String?
    var endDate: String?
    var details: String
}

struct EducationEntry {
    var degree: String
    var institution: String
    var startDate: String?
    var endDate: String?
}

struct ProjectEntry {
    var name: String
    var details: String
    var technologies: String
    var link: String?
}

struct ExtracurricularEntry {
    var title: String
    var organization: String
    var details: String
}

struct LanguageEntry {
    var name: String
    var proficiency: String
}

@MainActor
@Observable
final class ResumeParsingService {
    private let sectionHeaders: [String] = [
        "contact", "personal information", "kontakt", "persönliche daten", "personliche daten",
        "summary", "profile", "about", "zusammenfassung", "kurzprofil", "profil", "über mich", "uber mich",
        "experience", "work experience", "employment", "berufserfahrung", "berufliche erfahrung", "arbeitserfahrung", "beruflicher werdegang",
        "education", "academic background", "ausbildung", "studium", "bildung", "akademischer hintergrund",
        "skills", "technical skills", "languages", "fähigkeiten", "faehigkeiten", "kenntnisse", "kompetenzen", "sprachen",
        "projects", "projekte", "certifications", "awards", "interests", "aktivitäten", "aktivitaeten", "ehrenamt", "vereine",
        "other", "miscellaneous", "additional information", "additional info", "sonstiges", "sonstige angaben", "weitere angaben",
    ]

    // Main entry point for parsing a resume PDF
    nonisolated func parseResume(from url: URL, completion: @escaping (String) -> Void) {
        Task.detached {
            let text = await Self.parseResume(from: url)
            await MainActor.run {
                completion(text)
            }
        }
    }

    nonisolated static func parseResume(from url: URL) async -> String {
        guard let pdf = PDFDocument(url: url) else {
            return ""
        }
        // Try native PDF extraction first
        let text = extractTextFromPDF(pdf)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Fallback to OCR if empty (e.g., scanned images)
            return await extractTextUsingVision(pdf: pdf)
        }
        return text
    }

    private nonisolated static func extractTextFromPDF(_ pdf: PDFDocument) -> String {
        var fullText = ""
        for pageIndex in 0 ..< pdf.pageCount {
            if let page = pdf.page(at: pageIndex),
               let pageText = page.string {
                fullText.append(pageText)
                fullText.append("\n")
            }
        }
        return fullText
    }

    private nonisolated static func extractTextUsingVision(pdf: PDFDocument) async -> String {
        await withTaskGroup(of: String.self) { group in
            for pageIndex in 0 ..< pdf.pageCount {
                guard let page = pdf.page(at: pageIndex),
                      let pageImage = page
                        .thumbnail(of: CGSize(width: 2000, height: 2800), for: .mediaBox)
                        .cgImage
                else { continue }

                group.addTask {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    request.recognitionLanguages = ["de-DE", "en-US"]
                    let handler = VNImageRequestHandler(cgImage: pageImage, options: [:])
                    try? handler.perform([request])
                    guard let results = request.results as? [VNRecognizedTextObservation] else {
                        return ""
                    }
                    return results
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                }
            }

            var fullText = ""
            for await pageText in group {
                if !pageText.isEmpty {
                    fullText.append(pageText)
                    fullText.append("\n")
                }
            }
            return fullText
        }
    }

    // Updated pattern to match the exact headers from canonicalization
    private let sectionPattern: String =
        #"(?im)^\s*(CONTACT|PERSONAL\s*INFORMATION|SKILLS|TECHNICAL\s*SKILLS|WORK\s*EXPERIENCE|EMPLOYMENT|EXPERIENCE|EDUCATION|ACADEMIC\s*BACKGROUND|PROJECTS|EXTRACURRICULAR|ACTIVITIES|LANGUAGES|OTHER|MISCELLANEOUS|KONTAKT|PERS(?:Ö|OE)NLICHE\s*DATEN|ZUSAMMENFASSUNG|KURZPROFIL|PROFIL|ÜBER\s*MICH|UEBER\s*MICH|BERUFSERFAHRUNG|ARBEITSERFAHRUNG|WERDEGANG|AUSBILDUNG|STUDIUM|BILDUNG|PROJEKTE|AKTIVITÄTEN|AKTIVITAETEN|EHRENAMT|VEREINE|FÄHIGKEITEN|FAEHIGKEITEN|KENNTNISSE|KOMPETENZEN|SPRACHEN|SONSTIGES|SONSTIGE\s*ANGABEN|WEITERE\s*ANGABEN)\s*:?\s*$"#

    func splitSections(from text: String) -> [String: String] {
        var result: [String: String] = [:]
        let nsText = text as NSString

        // Find section header matches
        guard let regex = try? NSRegularExpression(pattern: sectionPattern) else {
            result["contact"] = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return result
        }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        // If no sections found, treat entire text as contact info
        guard !matches.isEmpty else {
            result["contact"] = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return result
        }

        // Handle text before first section (if any)
        let firstMatch = matches[0]
        if firstMatch.range.location > 0 {
            let beforeFirstSection = nsText
                .substring(to: firstMatch.range.location)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !beforeFirstSection.isEmpty {
                result["contact"] = beforeFirstSection
            }
        }

        // Process each section
        for (i, match) in matches.enumerated() {
            guard let headerRange = Range(match.range(at: 1), in: text) else { continue }

            let header = text[headerRange].lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: " ")

            let nextSectionStart = (i + 1 < matches.count) ?
                matches[i + 1].range.lowerBound : nsText.length

            // Extract section content
            let contentStart = match.range.upperBound
            let bodyRange = NSRange(location: contentStart,
                                    length: nextSectionStart - contentStart)

            let content = nsText.substring(with: bodyRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Map section headers to consistent keys
            let sectionKey = mapSectionHeader(header)
            if !content.isEmpty {
                result[sectionKey] = content
            }
        }

        return result
    }

    private func mapSectionHeader(_ header: String) -> String {
        let normalizedHeader = header.lowercased().trimmingCharacters(in: .whitespaces)

        if normalizedHeader.contains("contact")
            || normalizedHeader.contains("personal")
            || normalizedHeader.contains("kontakt")
        {
            return "contact"
        } else if normalizedHeader.contains("skill")
            || normalizedHeader.contains("fähigkeiten")
            || normalizedHeader.contains("faehigkeiten")
            || normalizedHeader.contains("kenntnisse")
            || normalizedHeader.contains("kompetenzen")
        {
            return "skills"
        } else if normalizedHeader.contains("experience")
            || normalizedHeader.contains("employment")
            || normalizedHeader.contains("work")
            || normalizedHeader.contains("berufserfahrung")
            || normalizedHeader.contains("arbeitserfahrung")
            || normalizedHeader.contains("werdegang")
        {
            return "work experience"
        } else if normalizedHeader.contains("education")
            || normalizedHeader.contains("academic")
            || normalizedHeader.contains("ausbildung")
            || normalizedHeader.contains("studium")
            || normalizedHeader.contains("bildung")
        {
            return "education"
        } else if normalizedHeader.contains("project") || normalizedHeader.contains("projekte") {
            return "projects"
        } else if normalizedHeader.contains("extracurricular")
            || normalizedHeader.contains("activit")
            || normalizedHeader.contains("aktivität")
            || normalizedHeader.contains("aktivitaet")
            || normalizedHeader.contains("ehrenamt")
            || normalizedHeader.contains("verein")
        {
            return "extracurricular"
        } else if normalizedHeader.contains("language") || normalizedHeader.contains("sprachen") {
            return "languages"
        } else if normalizedHeader.contains("other")
            || normalizedHeader.contains("misc")
            || normalizedHeader.contains("sonstiges")
            || normalizedHeader.contains("sonstige")
            || normalizedHeader.contains("weitere")
            || normalizedHeader.contains("additional")
        {
            return "miscellaneous"
        }
        return normalizedHeader
    }

    func extractContactInfo(from section: String) -> ContactInfo {
        var result = ContactInfo()

        // Split section into lines for better processing
        let lines = section.split(separator: "\n").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        // Email detection
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        if let emailMatch = section.range(of: emailPattern, options: .regularExpression) {
            result.email = String(section[emailMatch])
        }

        // Phone detection (slightly more lenient)
        let phonePattern =
            #"(\+\d{1,3}[\s.-]?)?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}"#
        if let phoneMatch = section.range(of: phonePattern, options: .regularExpression) {
            result.phone = String(section[phoneMatch])
        }

        // LinkedIn detection
        let linkedInPatterns = [
            #"(?i)(https?://)?(www\.)?linkedin\.com/in/[A-Za-z0-9_-]+"#,
            #"(?i)(https?://)?(www\.)?linkedin\.com/[A-Za-z0-9_-]+"#,
        ]
        for pattern in linkedInPatterns {
            if let m = section.range(of: pattern, options: .regularExpression) {
                var url = String(section[m])
                if !url.lowercased().hasPrefix("http") { url = "https://" + url }
                result.linkedIn = url
                break
            }
        }

        // GitHub detection
        let githubPattern = #"(?i)(https?://)?(www\.)?github\.com/[A-Za-z0-9._-]+"#
        if let m = section.range(of: githubPattern, options: .regularExpression) {
            var url = String(section[m])
            if !url.lowercased().hasPrefix("http") { url = "https://" + url }
            result.github = url
        }

        // Website (generic URL; avoid linkedin/github)
        let urlPattern = #"(?i)\bhttps?://[^\s]+"#
        if let m = section.range(of: urlPattern, options: .regularExpression) {
            let url = String(section[m])
            if result.linkedIn == nil && !url.lowercased().contains("linkedin.com")
                && result.github == nil && !url.lowercased().contains("github.com")
            {
                result.website = url
            }
        }

        // Location detection (city names or addresses)
        if result.location == nil {
            for line in lines {
                let low = line.lowercased()
                if line.contains(",")
                    && !low.contains("@")
                    && !low.contains("linkedin")
                    && !low.contains("github")
                    && !low.contains("http")
                {
                    result.location = line
                    break
                }
            }
        }

        // Name extraction (first non-link/email/http line)
        if let firstNameLine = lines.first(where: { l in
            let low = l.lowercased()
            return !l.isEmpty && !low.contains("@") && !low.contains("linkedin")
                && !low.contains("github") && !low.contains("http")
        }) {
            result.name = firstNameLine
        }

        return result
    }

    // More tolerant experience extractor
    func extractExperience(from section: String) -> [JobExperience] {
        var jobs: [JobExperience] = []
        let lines = section
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Date tokens and ranges
        let monthShort =
            #"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\.?"#
        let monthLong =
            #"(January|February|March|April|May|June|July|August|September|October|November|December)"#
        let mmyyyy = #"(?:\d{1,2}\/\d{2,4})"#
        let dateToken = "(?:\(monthShort)\\s*\\d{2,4}|\(monthLong)\\s*\\d{2,4}|\(mmyyyy)|(?:19|20)\\d{2})"
        let rangeRegex =
            try? NSRegularExpression(pattern: "(?i)\(dateToken)\\s*[–—-]\\s*(Present|Current|\(dateToken))")

        func hasRange(_ s: String) -> NSTextCheckingResult? {
            guard let rangeRegex else { return nil }
            let ns = s as NSString
            let r = NSRange(location: 0, length: ns.length)
            return rangeRegex.firstMatch(in: s, range: r)
        }

        func parseHeader(_ s: String) -> (String, String) {
            // Prefer "Title at Company"
            if let r = s.range(of: #"(?i)^(.*?)\s+at\s+(.*)$"#,
                                options: .regularExpression)
            {
                let parts = String(s[r]).components(separatedBy: " at ")
                if parts.count == 2 {
                    return (parts[0].trimmingCharacters(in: .whitespaces),
                            parts[1].trimmingCharacters(in: .whitespaces))
                }
            }
            // Try "Company — Title" or "Company - Title"
            if let r = s.range(of: #"(?i)^(.*?)\s*[–—-]\s*(.*)$"#,
                                options: .regularExpression)
            {
                let prefix = String(s[s.startIndex..<r.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                let suffix = String(s[r.upperBound...])
                    .trimmingCharacters(in: .whitespaces)
                // Assume suffix is title
                return (suffix, prefix)
            }
            // Fallback: comma/pipe split
            let parts = s.components(separatedBy: CharacterSet(charactersIn: ",|"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 { return (parts[0], parts[1]) }
            return (s, "")
        }

        var current: JobExperience?
        var headerBuffer: String?

        func flush() {
            if var j = current, !j.title.isEmpty, !j.company.isEmpty {
                j.details = j.details.trimmingCharacters(in: .whitespacesAndNewlines)
                jobs.append(j)
            }
            current = nil
            headerBuffer = nil
        }

        for raw in lines {
            let line = raw
            if line.isEmpty { continue }

            if let m = hasRange(line) {
                // New job entry
                // Header is text before the first date token
                let nsLine = line as NSString
                let header = nsLine.substring(to: m.range.location)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                var start: String?
                var end: String?
                // Extract the matched range string and split on dash
                let matched = nsLine.substring(with: m.range)
                // Try to split around the dash variants
                let split = matched.components(separatedBy: CharacterSet(charactersIn: "–—-"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                if split.count == 2 {
                    start = split[0]
                    end = split[1]
                }

                // Commit previous
                flush()

                let (title, company) = parseHeader(header.isEmpty ? (headerBuffer ?? "") : header)
                current = JobExperience(
                    title: title,
                    company: company,
                    startDate: start,
                    endDate: end,
                    details: ""
                )
                headerBuffer = nil
            } else if current == nil {
                // Accumulate header before date line appears (common two-line headers)
                if headerBuffer == nil {
                    headerBuffer = line
                } else {
                    // Merge with a separator
                    headerBuffer = (headerBuffer ?? "") + " " + line
                }
            } else {
                // Details for current job
                if !line.isEmpty {
                    let normalized = line.replacingOccurrences(
                        of: #"^\s*[-*]\s+"#,
                        with: "• ",
                        options: .regularExpression
                    )
                    if current!.details.isEmpty {
                        current!.details = normalized
                    } else {
                        current!.details.append("\n" + normalized)
                    }
                }
            }
        }

        // Append the last job entry
        flush()

        return jobs
    }

    func extractEducation(from section: String) -> [EducationEntry] {
        var entries: [EducationEntry] = []
        let lines = section
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
        let datePattern =
            #"(?i)([A-Za-z]{3,}\.?\s?\d{2,4}|[0-9]{1,2}\/\d{2,4}|(19|20)\d{2})\s?[-–—]\s?([A-Za-z]{3,}\.?\s?\d{2,4}|Present|Current|[0-9]{1,2}\/\d{2,4}|(19|20)\d{2})"#
        let dateRegex = try? NSRegularExpression(pattern: datePattern)

        var currentEntry: EducationEntry?

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            let dateMatch = dateRegex?.firstMatch(in: line, range: range)

            if let dateMatch = dateMatch {
                if let entry = currentEntry { entries.append(entry) }

                let institutionAndDegree = nsLine
                    .substring(to: dateMatch.range.location)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = institutionAndDegree
                    .components(separatedBy: CharacterSet(charactersIn: ",-–—|"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                currentEntry = EducationEntry(
                    degree: parts.count > 1 ? parts[1] : "",
                    institution: parts.first ?? "",
                    startDate: nsLine.substring(with: dateMatch.range(at: 1)),
                    endDate: nsLine.substring(with: dateMatch.range(at: 3))
                )
            } else if currentEntry != nil {
                if currentEntry?.degree.isEmpty ?? false {
                    currentEntry?.degree = line
                }
            } else if !line.isEmpty {
                let parts = line
                    .components(separatedBy: CharacterSet(charactersIn: ",-–—|"))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                currentEntry = EducationEntry(
                    degree: parts.count > 1 ? parts[1] : "",
                    institution: parts.first ?? "",
                    startDate: nil,
                    endDate: nil
                )
            }
        }

        if let entry = currentEntry { entries.append(entry) }

        return entries
    }

    func extractSkills(from section: String) -> [String] {
        let lines = section
            .split(whereSeparator: \.isNewline)
            .flatMap { line -> [String] in
                let str = String(line)
                if let colonIndex = str.firstIndex(of: ":") {
                    return str[str.index(after: colonIndex)...]
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                }

                let comps = str
                    .components(separatedBy: CharacterSet(charactersIn: "•*-"))
                    .flatMap { $0.components(separatedBy: ",") }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                return comps
            }
        return lines
    }

    func extractProjects(from section: String) -> [ProjectEntry] {
        var projects: [ProjectEntry] = []
        let lines = section.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        var buffer: [String] = []

        func flush() {
            guard !buffer.isEmpty else { return }
            let name = buffer.first ?? ""
            let details = buffer.dropFirst().joined(separator: "\n")
            projects.append(
                ProjectEntry(name: name, details: details, technologies: "", link: nil)
            )
            buffer.removeAll()
        }

        for line in lines {
            if line.isEmpty, !buffer.isEmpty {
                flush()
            } else if !line.isEmpty {
                buffer.append(line)
            }
        }
        flush()

        return projects
    }

    func extractExtracurriculars(from section: String) -> [ExtracurricularEntry] {
        var entries: [ExtracurricularEntry] = []
        let lines = section.components(separatedBy: .newlines).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        var buffer: [String] = []

        func flush() {
            guard !buffer.isEmpty else { return }
            let title = buffer[safe: 0] ?? ""
            let org = buffer[safe: 1] ?? ""
            let desc = buffer.dropFirst(2).joined(separator: " ")
            entries.append(
                ExtracurricularEntry(title: title, organization: org, details: desc)
            )
            buffer.removeAll()
        }

        for line in lines {
            if line.isEmpty, !buffer.isEmpty {
                flush()
            } else if !line.isEmpty {
                buffer.append(line)
            }
        }
        flush()

        return entries
    }

    func extractLanguages(from section: String) -> [LanguageEntry] {
        // Support "(Proficiency)" or "- Proficiency"
        let pattern = #"(.+?)\s*\((.+?)\)"#
        let regex = try? NSRegularExpression(pattern: pattern)

        let tokens = section
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var entries: [LanguageEntry] = []
        for token in tokens where !token.isEmpty {
            if let regex = regex,
               let match = regex.firstMatch(
                   in: token,
                   range: NSRange(location: 0, length: token.utf16.count)
               ),
               let nameRange = Range(match.range(at: 1), in: token),
               let profRange = Range(match.range(at: 2), in: token)
            {
                let name = String(token[nameRange]).trimmingCharacters(in: .whitespaces)
                let prof = String(token[profRange]).trimmingCharacters(in: .whitespaces)
                entries.append(LanguageEntry(name: name, proficiency: prof))
            } else if token.contains("-") || token.contains("–") || token.contains("—") {
                let parts = token.split(whereSeparator: { "–—-".contains($0) })
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    entries.append(LanguageEntry(name: parts[0], proficiency: parts[1]))
                } else {
                    entries.append(LanguageEntry(name: token, proficiency: ""))
                }
            } else {
                entries.append(LanguageEntry(name: token, proficiency: ""))
            }
        }
        return entries
    }

    nonisolated func canonicalize(text: String, ai: any AIProvider) async throws -> String {
      let systemPrompt = """
      You are a résumé parser. Reorganize résumé text into this EXACT format with these EXACT headers:
      
      CONTACT:
      [Full Name]
      [Email]
      [Phone]
      [Address/Location]
      [LinkedIn URL if available]
      [Website/GitHub if available]

      SKILLS:
      [List skills separated by commas or bullets, group by category if possible]
      
      WORK EXPERIENCE:
      [Job Title] at [Company Name]
      [Location] | [Start Date] - [End Date or Present]
      • [Responsibility/achievement]
      • [Responsibility/achievement]

      [Repeat for each job]

      EDUCATION:
      [Degree] in [Field] from [School Name]
      [Start Date] - [End Date]
      [Additional details if any]

      [Repeat for each education entry]

      PROJECTS:
      [Project Name]
      [Description and details]
      Technologies: [Tech stack]
      Link: [URL if available]

      [Repeat for each project]

      EXTRACURRICULAR:
      [Title/Role] at [Organization]
      [Description and details]

      [Repeat for each activity]

      LANGUAGES:
      [Language] ([Proficiency level]), [Language] ([Proficiency level])

      SONSTIGES:
      [Additional information, certifications, interests, or other relevant details]

      Rules:
      1. Use ONLY the exact headers above followed by a colon
      2. Do NOT add bold formatting, asterisks, or extra punctuation
      3. Do NOT add placeholder text like "[insert URL]" or explanatory notes
      4. Do NOT invent information not in the original text
      5. If a section is empty, include the header but leave the content blank
      6. Remove redundant or duplicate information
      7. Keep all factual content from the original résumé
      8. Format dates as "MMM YYYY" (e.g., "Oct 2022")
      9. Use bullet points (•) for lists and job responsibilities
      """

      let userPrompt = """
      Reorganize this résumé text using the exact format:

      \(text)
      """

      let response = try await ai.processText(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        images: [],
        streaming: false
      )

      return cleanCanonicalizedText(response)
    }

    private nonisolated func cleanCanonicalizedText(_ text: String) -> String {
        var cleaned = text

        // Remove bold markdown formatting
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")

        // Remove placeholder text patterns
        cleaned = cleaned.replacingOccurrences(
            of: #"\[insert [^\]]+\]"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"\[[^\]]+\]"#,
            with: "",
            options: .regularExpression
        )

        // Remove explanatory notes that start with "Note:" or "Important:"
        cleaned = cleaned.replacingOccurrences(
            of: #"(?m)^\s*(Note|Important|Skills are categorized).*$"#,
            with: "",
            options: .regularExpression
        )

        // Ensure section headers are properly formatted
        let headers = [
            "CONTACT", "SKILLS", "WORK EXPERIENCE", "EDUCATION", "PROJECTS",
            "EXTRACURRICULAR", "LANGUAGES", "SONSTIGES",
        ]
        for header in headers {
            let pattern = "(?im)^\\s*\(header)\\s*:?.*$"
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "\(header):",
                options: .regularExpression
            )
        }

        // Normalize bullets to "• "
        cleaned = cleaned.replacingOccurrences(
            of: #"(?m)^\s*[-*]\s+"#,
            with: "• ",
            options: .regularExpression
        )

        // Clean up multiple consecutive newlines
        cleaned = cleaned.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        // Fix email extraction (remove 'coderary@' if it appears)
        cleaned = cleaned.replacingOccurrences(of: "coderary@", with: "")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

fileprivate extension Array {
    subscript(safe idx: Int) -> Element? { (indices.contains(idx)) ? self[idx] : nil }
}
