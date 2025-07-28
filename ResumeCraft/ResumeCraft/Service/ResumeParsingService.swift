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

@Observable
final class ResumeParsingService {
    private let sectionHeaders: [String] = [
        "contact", "personal information",
        "summary", "profile", "about",
        "experience", "work experience", "employment",
        "education", "academic background",
        "skills", "technical skills", "languages",
        "projects", "certifications", "awards", "interests",
    ]

    // Main entry point for parsing a resume PDF
    func parseResume(from url: URL, completion: @escaping (String) -> Void) {
        guard let pdf = PDFDocument(url: url) else {
            completion("")
            return
        }
        // Try native PDF extraction first
        let text = extractTextFromPDF(pdf)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Fallback to OCR if empty (e.g., scanned images)
            extractTextUsingVision(pdf: pdf, completion: completion)
        } else {
            completion(text)
        }
    }

    private func extractTextFromPDF(_ pdf: PDFDocument) -> String {
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

    private func extractTextUsingVision(pdf: PDFDocument, completion: @escaping (String) -> Void) {
        let dispatchGroup = DispatchGroup()
        var fullText = ""
        for pageIndex in 0 ..< pdf.pageCount {
            if let page = pdf.page(at: pageIndex),
               let pageImage = page.thumbnail(of: CGSize(width: 2000, height: 2800), for: .mediaBox).cgImage {
                dispatchGroup.enter()
                let request = VNRecognizeTextRequest { req, _ in
                    defer { dispatchGroup.leave() }
                    guard let results = req.results as? [VNRecognizedTextObservation] else { return }
                    let pageText = results.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    fullText.append(pageText)
                    fullText.append("\n")
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: pageImage, options: [:])
                try? handler.perform([request])
            }
        }
        dispatchGroup.notify(queue: .main) {
            completion(fullText)
        }
    }

    // Updated pattern to match the exact headers from canonicalization
    private let sectionPattern: String =
        #"(?im)^\s*(CONTACT|PERSONAL\s*INFORMATION|SKILLS|TECHNICAL\s*SKILLS|WORK\s*EXPERIENCE|EMPLOYMENT|EXPERIENCE|EDUCATION|ACADEMIC\s*BACKGROUND|PROJECTS|EXTRACURRICULAR|ACTIVITIES|LANGUAGES)\s*:?\s*$"#

    func splitSections(from text: String) -> [String: String] {
        var result: [String: String] = [:]
        let nsText = text as NSString

        // Find section header matches
        let regex = try! NSRegularExpression(pattern: sectionPattern)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        // If no sections found, treat entire text as contact info
        guard !matches.isEmpty else {
            result["contact"] = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return result
        }

        // Handle text before first section (if any)
        let firstMatch = matches[0]
        if firstMatch.range.location > 0 {
            let beforeFirstSection = nsText.substring(to: firstMatch.range.location)
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
                .replacingOccurrences(of: " ", with: " ") // Normalize spaces

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
        
        if normalizedHeader.contains("contact") || normalizedHeader.contains("personal") {
            return "contact"
        } else if normalizedHeader.contains("skill") {
            return "skills"
        } else if normalizedHeader.contains("experience") || normalizedHeader.contains("employment") ||
                  normalizedHeader.contains("work") {
            return "work experience"
        } else if normalizedHeader.contains("education") || normalizedHeader.contains("academic") {
            return "education"
        } else if normalizedHeader.contains("project") {
            return "projects"
        } else if normalizedHeader.contains("extracurricular") || normalizedHeader.contains("activit") {
            return "extracurricular"
        } else if normalizedHeader.contains("language") {
            return "languages"
        }
        return normalizedHeader
    }

    func extractContactInfo(from section: String) -> ContactInfo {
        var result = ContactInfo()
        
        // Split section into lines for better processing
        let lines = section.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Email detection with improved regex
        let emailPattern = #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#
        if let emailMatch = section.range(of: emailPattern, options: .regularExpression) {
            result.email = String(section[emailMatch])
        }
        
        // Phone detection with improved regex
        let phonePattern = #"(\+\d{1,3}[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}"#
        if let phoneMatch = section.range(of: phonePattern, options: .regularExpression) {
            result.phone = String(section[phoneMatch])
        }
        
        // LinkedIn detection
        let linkedInPatterns = [
            #"linkedin\.com/in/[A-Za-z0-9_-]+"#,
            #"linkedin\.com/[A-Za-z0-9_-]+"#
        ]
        
        for pattern in linkedInPatterns {
            if let linkedInMatch = section.range(of: pattern, options: .regularExpression) {
                result.linkedIn = "https://www." + String(section[linkedInMatch])
                break
            }
        }
        
        // Location detection (city names or addresses)
        if result.location == nil {
            // Try to find a line that looks like a location
            for line in lines {
                if line.contains(",") && !line.contains("@") && !line.contains("linkedin") {
                    result.location = line
                    break
                }
            }
        }
        
        // Name extraction (usually the first line or two)
        if let firstLine = lines.first, !firstLine.isEmpty &&
           !firstLine.contains("@") && !firstLine.contains("linkedin") &&
           !firstLine.contains("github") && !firstLine.contains("http") {
            result.name = firstLine
        } else if lines.count > 1 {
            result.name = lines[1]
        }
        
        return result
    }

    func extractExperience(from section: String) -> [JobExperience] {
        var jobs: [JobExperience] = []
        let lines = section.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
        let datePattern = #"(?i)([A-Za-z]{3,}\s?\d{4}|[0-9]{1,2}\/\d{4})\s?[-–—]\s?([A-Za-z]{3,}\s?\d{4}|Present|[0-9]{1,2}\/\d{4})"#
        let dateRegex = try! NSRegularExpression(pattern: datePattern)

        var currentJob: JobExperience?

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            let dateMatch = dateRegex.firstMatch(in: line, range: range)

            if let dateMatch = dateMatch {
                // This line contains a date range, likely indicating a new job entry.
                // First, save the previous job if it exists.
                if var job = currentJob, !job.title.isEmpty, !job.company.isEmpty {
                    job.details = job.details.trimmingCharacters(in: .whitespacesAndNewlines)
                    jobs.append(job)
                }

                // Start a new job entry
                let companyAndTitle = nsLine.substring(to: dateMatch.range.location).trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = companyAndTitle.components(separatedBy: CharacterSet(charactersIn: ",-–—|")).map { $0.trimmingCharacters(in: .whitespaces) }

                currentJob = JobExperience(
                    title: parts.first ?? "",
                    company: parts.count > 1 ? parts[1] : "",
                    startDate: nsLine.substring(with: dateMatch.range(at: 1)),
                    endDate: nsLine.substring(with: dateMatch.range(at: 2)),
                    details: ""
                )
            } else if currentJob != nil {
                // This is a detail line for the current job.
                if !line.isEmpty {
                    currentJob?.details.append(line + "\n")
                }
            }
        }

        // Append the last job entry
        if var job = currentJob, !job.title.isEmpty, !job.company.isEmpty {
            job.details = job.details.trimmingCharacters(in: .whitespacesAndNewlines)
            jobs.append(job)
        }

        return jobs
    }

    func extractEducation(from section: String) -> [EducationEntry] {
        var entries: [EducationEntry] = []
        let lines = section.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
        let datePattern = #"(?i)([A-Za-z]{3,}\s?\d{4}|[0-9]{1,2}\/\d{4})\s?[-–—]\s?([A-Za-z]{3,}\s?\d{4}|Present|[0-9]{1,2}\/\d{4})"#
        let dateRegex = try! NSRegularExpression(pattern: datePattern)

        var currentEntry: EducationEntry?

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            let dateMatch = dateRegex.firstMatch(in: line, range: range)

            if let dateMatch = dateMatch {
                if let entry = currentEntry { entries.append(entry) }

                let institutionAndDegree = nsLine.substring(to: dateMatch.range.location).trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = institutionAndDegree.components(separatedBy: CharacterSet(charactersIn: ",-–—|")).map { $0.trimmingCharacters(in: .whitespaces) }

                currentEntry = EducationEntry(
                    degree: parts.count > 1 ? parts[1] : "",
                    institution: parts.first ?? "",
                    startDate: nsLine.substring(with: dateMatch.range(at: 1)),
                    endDate: nsLine.substring(with: dateMatch.range(at: 2))
                )
            } else if currentEntry != nil {
                // Assume the line after the institution is the degree if it wasn't on the same line
                if currentEntry?.degree.isEmpty ?? false {
                    currentEntry?.degree = line
                }
            } else if !line.isEmpty {
                // This might be the first line (institution) before a date line
                let parts = line.components(separatedBy: CharacterSet(charactersIn: ",-–—|")).map { $0.trimmingCharacters(in: .whitespaces) }
                currentEntry = EducationEntry(degree: parts.count > 1 ? parts[1] : "", institution: parts.first ?? "", startDate: nil, endDate: nil)
            }
        }

        if let entry = currentEntry { entries.append(entry) }

        return entries
    }

    func extractSkills(from section: String) -> [String] {
        // Look for lines separated by commas, bullets, or newlines
        let lines = section
            .split(whereSeparator: \.isNewline)
            .flatMap { line -> [String] in
                // Split on bullets or commas
                let str = String(line)
                // Handle "Category: Skill, Skill, Skill" format
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
        let lines = section.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var buffer: [String] = []

        for line in lines {
            if line.isEmpty, !buffer.isEmpty {
                // End of a project block
                let name = buffer.first ?? ""
                let details = buffer.dropFirst().joined(separator: "\n")
                projects.append(ProjectEntry(name: name, details: details, technologies: "", link: nil))
                buffer.removeAll()
            } else if !line.isEmpty {
                buffer.append(line)
            }
        }

        if !buffer.isEmpty {
            // Add the last project
            let name = buffer.first ?? ""
            let details = buffer.dropFirst().joined(separator: "\n")
            projects.append(ProjectEntry(name: name, details: details, technologies: "", link: nil))
        }

        return projects
    }

    func extractExtracurriculars(from section: String) -> [ExtracurricularEntry] {
        var entries: [ExtracurricularEntry] = []
        let lines = section.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        var buffer: [String] = []

        for line in lines {
            if line.isEmpty, !buffer.isEmpty {
                let title = buffer[safe: 0] ?? ""
                let org = buffer[safe: 1] ?? ""
                let desc = buffer.dropFirst(2).joined(separator: " ")
                entries.append(ExtracurricularEntry(title: title, organization: org, details: desc))
                buffer.removeAll()
            } else if !line.isEmpty {
                buffer.append(line)
            }
        }

        if !buffer.isEmpty {
            let title = buffer[safe: 0] ?? ""
            let org = buffer[safe: 1] ?? ""
            let desc = buffer.dropFirst(2).joined(separator: " ")
            entries.append(ExtracurricularEntry(title: title, organization: org, details: desc))
        }

        return entries
    }

    func extractLanguages(from section: String) -> [LanguageEntry] {
        // Expected: "English (Native)", "French (C1)", or just "English, French"
        let pattern = #"(.+?)\s*\((.+?)\)"#
        let regex = try? NSRegularExpression(pattern: pattern)

        let languageTokens = section.components(separatedBy: CharacterSet(charactersIn: ",\n")).map { $0.trimmingCharacters(in: .whitespaces) }

        var entries: [LanguageEntry] = []
        for token in languageTokens where !token.isEmpty {
            if let regex = regex,
               let match = regex.firstMatch(in: token, range: NSRange(location: 0, length: token.utf16.count)),
               let nameRange = Range(match.range(at: 1), in: token),
               let profRange = Range(match.range(at: 2), in: token) {
                let name = String(token[nameRange]).trimmingCharacters(in: .whitespaces)
                let prof = String(token[profRange]).trimmingCharacters(in: .whitespaces)
                entries.append(LanguageEntry(name: name, proficiency: prof))
            } else {
                entries.append(LanguageEntry(name: token, proficiency: ""))
            }
        }
        return entries
    }

    func canonicalize(text: String, mlxService: MLXService) async throws -> String {
        print("Before canon: \(text)")

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

        let thread = Thread(title: "Resume Canonicalization")
        thread.addMessage(Message(content: userPrompt, role: .user))
        let result = await mlxService.generate(thread: thread, systemPrompt: systemPrompt)

        // Clean up the result to remove common AI artifacts
        let cleanedResult = cleanCanonicalizedText(result)

        print("After canon: \(cleanedResult)")

        return cleanedResult
    }

    private func cleanCanonicalizedText(_ text: String) -> String {
        var cleaned = text

        // Remove bold markdown formatting
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        
        // Remove placeholder text patterns
        cleaned = cleaned.replacingOccurrences(of: #"\[insert [^\]]+\]"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"\[[^\]]+\]"#, with: "", options: .regularExpression)
        
        // Remove explanatory notes that start with "Note:" or "Important:"
        cleaned = cleaned.replacingOccurrences(of: #"(?m)^\s*(Note|Important|Skills are categorized).*$"#, with: "", options: .regularExpression)
        
        // Ensure section headers are properly formatted
        let headers = ["CONTACT", "SKILLS", "WORK EXPERIENCE", "EDUCATION", "PROJECTS", "EXTRACURRICULAR", "LANGUAGES"]
        for header in headers {
            // Convert any case variation to uppercase with colon
            let pattern = "(?i)^\\s*\(header)\\s*:?" + "\\s*$"
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "\(header):",
                options: .regularExpression
            )
        }
        
        // Fix section headers that might be missing the colon
        for header in headers {
            let pattern = "(?m)^\\s*\(header)\\s*$"
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "\(header):",
                options: .regularExpression
            )
        }
        
        // Clean up multiple consecutive newlines
        cleaned = cleaned.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        
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
