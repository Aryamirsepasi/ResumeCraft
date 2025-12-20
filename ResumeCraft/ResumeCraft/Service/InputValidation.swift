//
//  InputValidation.swift
//  ResumeCraft
//
//  Input validation extensions for resume fields
//

import Foundation

// MARK: - Validation Result

enum ValidationResult: Equatable {
    case valid
    case invalid(message: String)
    case warning(message: String)
    
    var isValid: Bool {
        switch self {
        case .valid, .warning: return true
        case .invalid: return false
        }
    }
    
    var message: String? {
        switch self {
        case .valid: return nil
        case .invalid(let msg), .warning(let msg): return msg
        }
    }
    
    var icon: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .valid: return "green"
        case .invalid: return "red"
        case .warning: return "yellow"
        }
    }
}

// MARK: - String Validation Extensions

extension String {
    
    // MARK: - Email Validation
    
    /// Validates email format
    var isValidEmail: Bool {
        let emailPattern = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return self.range(of: emailPattern, options: .regularExpression) != nil
    }
    
    func validateEmail() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid(message: "E-Mail ist erforderlich")
        }
        
        if !trimmed.isValidEmail {
            return .invalid(message: "Bitte gib eine gültige E-Mail-Adresse ein")
        }
        
        // Check for professional email
        let unprofessionalDomains = ["hotmail.com", "aol.com", "yahoo.com"]
        if unprofessionalDomains.contains(where: { trimmed.lowercased().hasSuffix($0) }) {
            return .warning(message: "Erwäge eine professionelle E-Mail-Domain")
        }
        
        return .valid
    }
    
    // MARK: - Phone Validation
    
    /// Validates phone number format (flexible international format)
    var isValidPhone: Bool {
        let phonePattern = #"^[\+]?[(]?[0-9]{1,3}[)]?[-\s\.]?[0-9]{1,4}[-\s\.]?[0-9]{1,4}[-\s\.]?[0-9]{1,9}$"#
        let digitsOnly = self.filter { $0.isNumber }
        return digitsOnly.count >= 7 && digitsOnly.count <= 15 &&
               self.range(of: phonePattern, options: .regularExpression) != nil
    }
    
    func validatePhone() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "Telefonnummer empfohlen für Recruiter-Kontakt")
        }
        
        let digitsOnly = trimmed.filter { $0.isNumber }
        
        if digitsOnly.count < 7 {
            return .invalid(message: "Telefonnummer wirkt zu kurz")
        }
        
        if digitsOnly.count > 15 {
            return .invalid(message: "Telefonnummer wirkt zu lang")
        }
        
        if !trimmed.isValidPhone {
            return .invalid(message: "Bitte gib eine gültige Telefonnummer ein")
        }
        
        return .valid
    }
    
    // MARK: - URL Validation
    
    /// Validates URL format
    var isValidURL: Bool {
        guard let url = normalizedURL else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    private var normalizedURLString: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        
        var urlString = trimmed
        let lowercased = urlString.lowercased()
        if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        return urlString
    }
    
    private var normalizedURL: URL? {
        guard let urlString = normalizedURLString else { return nil }
        return URL(string: urlString)
    }
    
    func validateURL(allowEmpty: Bool = true) -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return allowEmpty ? .valid : .invalid(message: "URL ist erforderlich")
        }
        
        guard
            let url = trimmed.normalizedURL,
            let scheme = url.scheme,
            let host = url.host,
            !scheme.isEmpty,
            !host.isEmpty
        else {
            return .invalid(message: "Bitte gib eine gültige URL ein")
        }
        
        return .valid
    }
    
    // MARK: - LinkedIn Validation
    
    /// Validates LinkedIn profile URL
    var isValidLinkedIn: Bool {
        guard
            let url = normalizedURL,
            let host = url.host?.lowercased()
        else {
            return false
        }
        
        if host != "linkedin.com" && !host.hasSuffix(".linkedin.com") {
            return false
        }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let pathRoot = pathComponents.first?.lowercased()
        return (pathRoot == "in" || pathRoot == "pub") && pathComponents.count >= 2
    }
    
    func validateLinkedIn() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "LinkedIn-Profil dringend empfohlen (94 % der Recruiter nutzen es)")
        }
        
        guard
            let url = trimmed.normalizedURL,
            let host = url.host?.lowercased()
        else {
            return .invalid(message: "Bitte gib eine gültige LinkedIn-URL ein")
        }
        
        if host != "linkedin.com" && !host.hasSuffix(".linkedin.com") {
            return .invalid(message: "Bitte gib eine gültige LinkedIn-URL ein")
        }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let pathRoot = pathComponents.first?.lowercased()
        if pathRoot != "in" && pathRoot != "pub" || pathComponents.count < 2 {
            return .warning(message: "Das sieht nicht wie eine Profil-URL aus. Erwartetes Format: linkedin.com/in/deinname")
        }
        
        return .valid
    }
    
    // MARK: - GitHub Validation
    
    /// Validates GitHub profile URL
    var isValidGitHub: Bool {
        guard
            let url = normalizedURL,
            let host = url.host?.lowercased()
        else {
            return false
        }
        
        return host == "github.com" || host.hasSuffix(".github.com")
    }
    
    func validateGitHub() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .valid // GitHub is optional for non-tech roles
        }
        
        guard
            let url = trimmed.normalizedURL,
            let host = url.host?.lowercased()
        else {
            return .invalid(message: "Bitte gib eine gültige GitHub-URL ein")
        }
        
        if host != "github.com" && !host.hasSuffix(".github.com") {
            return .invalid(message: "Bitte gib eine gültige GitHub-URL ein")
        }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        if pathComponents.count > 1 {
            return .warning(message: "Das sieht wie eine Repository-URL aus. Bitte nutze stattdessen deine Profil-URL")
        }
        
        return .valid
    }
    
    // MARK: - Website Validation
    
    func validateWebsite() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .valid // Website is optional
        }
        
        return validateURL(allowEmpty: false)
    }
    
    // MARK: - Name Validation
    
    func validateName(fieldName: String = "Name") -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid(message: "\(fieldName) ist erforderlich")
        }
        
        if trimmed.count < 2 {
            return .invalid(message: "\(fieldName) ist zu kurz")
        }
        
        if trimmed.count > 50 {
            return .warning(message: "\(fieldName) ist ungewöhnlich lang")
        }
        
        // Check for numbers in name
        if trimmed.contains(where: { $0.isNumber }) {
            return .warning(message: "\(fieldName) enthält Zahlen")
        }
        
        return .valid
    }
    
    // MARK: - Summary Validation
    
    func validateSummary() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "Eine professionelle Zusammenfassung hilft Recruitern, deinen Mehrwert schnell zu erfassen")
        }
        
        let wordCount = trimmed.split(separator: " ").count
        
        if wordCount < 20 {
            return .warning(message: "Die Zusammenfassung ist zu kurz. Ziel: 50–100 Wörter")
        }
        
        if wordCount > 150 {
            return .warning(message: "Die Zusammenfassung ist zu lang. Halte sie für maximale Wirkung unter 100 Wörtern")
        }
        
        // Check for first-person pronouns
        let lowered = trimmed.lowercased()
        let hasFirstPerson = lowered.contains("i ") ||
                            lowered.contains("my ") ||
                            lowered.contains(" me ") ||
                            lowered.contains("ich ") ||
                            lowered.contains("mein ") ||
                            lowered.contains("meine ") ||
                            lowered.contains("mich ") ||
                            lowered.contains("mir ")
        
        if hasFirstPerson {
            return .warning(message: "Erwäge die Formulierung in der dritten Person oder impliziten ersten Person")
        }
        
        return .valid
    }
    
    // MARK: - Job Details Validation
    
    func validateJobDetails() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "Ergänze Details zu Verantwortungen und Erfolgen")
        }
        
        // Check for metrics
        let hasMetrics = trimmed.contains(where: { $0.isNumber }) ||
                        trimmed.contains("%") ||
                        trimmed.contains("$")
        
        if !hasMetrics {
            return .warning(message: "Erwäge messbare Kennzahlen (Zahlen, Prozente)")
        }
        
        // Check for weak verbs
        let weakVerbs = [
            "responsible for",
            "helped",
            "worked on",
            "involved in",
            "assisted with",
            "zuständig für",
            "geholfen",
            "mitgearbeitet",
            "beteiligt",
            "unterstützt",
        ]
        let hasWeakVerbs = weakVerbs.contains(where: { trimmed.lowercased().contains($0) })
        
        if hasWeakVerbs {
            return .warning(message: "Verwende stärkere Aktionsverben (z. B. \"geleitet\", \"erreicht\", \"vorangetrieben\", \"gebaut\")")
        }
        
        return .valid
    }
}

// MARK: - PersonalInfo Validation Extension

extension PersonalInfo {
    
    /// Validates all personal info fields
    func validate() -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        results["firstName"] = firstName.validateName(fieldName: "Vorname")
        results["lastName"] = lastName.validateName(fieldName: "Nachname")
        results["email"] = email.validateEmail()
        results["phone"] = phone.validatePhone()
        results["linkedIn"] = (linkedIn ?? "").validateLinkedIn()
        results["github"] = (github ?? "").validateGitHub()
        results["website"] = (website ?? "").validateWebsite()
        
        return results
    }
    
    /// Returns overall validation status
    var isValid: Bool {
        let results = validate()
        return !results.values.contains(where: { 
            if case .invalid = $0 { return true }
            return false
        })
    }
    
    /// Returns count of validation issues
    var validationIssueCount: Int {
        let results = validate()
        return results.values.filter { 
            switch $0 {
            case .invalid, .warning: return true
            case .valid: return false
            }
        }.count
    }
}

// MARK: - Date Validation

extension Date {
    
    /// Validates that end date is after start date
    func validateEndDate(after startDate: Date) -> ValidationResult {
        if self < startDate {
            return .invalid(message: "Enddatum muss nach dem Startdatum liegen")
        }
        
        if self > Date() {
            return .warning(message: "Enddatum liegt in der Zukunft")
        }
        
        return .valid
    }
    
    /// Validates that date is not too far in the past
    func validateReasonableDate(maxYearsAgo: Int = 50) -> ValidationResult {
        let calendar = Calendar.current
        let yearsAgo = calendar.date(byAdding: .year, value: -maxYearsAgo, to: Date())!
        
        if self < yearsAgo {
            return .warning(message: "Datum wirkt ungewöhnlich weit in der Vergangenheit")
        }
        
        if self > Date() {
            return .warning(message: "Datum liegt in der Zukunft")
        }
        
        return .valid
    }
}

// MARK: - Skill Validation

extension Skill {
    
    func validate() -> ValidationResult {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(message: "Fähigkeitsname ist erforderlich")
        }
        
        if name.count > 50 {
            return .warning(message: "Fähigkeitsname ist zu lang")
        }
        
        return .valid
    }
}

// MARK: - WorkExperience Validation

extension WorkExperience {
    
    func validate() -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        results["title"] = title.isEmpty ? 
            .invalid(message: "Jobtitel ist erforderlich") : .valid
        results["company"] = company.isEmpty ? 
            .invalid(message: "Unternehmensname ist erforderlich") : .valid
        results["details"] = details.validateJobDetails()
        
        if !isCurrent, let endDate = endDate {
            results["dates"] = endDate.validateEndDate(after: startDate)
        }
        
        return results
    }
    
    var isValid: Bool {
        let results = validate()
        return !results.values.contains(where: { 
            if case .invalid = $0 { return true }
            return false
        })
    }
}

// MARK: - Project Validation

extension Project {
    
    func validate() -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        results["name"] = name.isEmpty ? 
            .invalid(message: "Projektname ist erforderlich") : .valid
        results["details"] = details.isEmpty ? 
            .warning(message: "Füge eine Projektbeschreibung für mehr Kontext hinzu") : .valid
        results["technologies"] = technologies.isEmpty ? 
            .warning(message: "Liste die in diesem Projekt verwendeten Technologien auf") : .valid
        
        if let link = link, !link.isEmpty {
            results["link"] = link.validateURL(allowEmpty: true)
        }
        
        return results
    }
}

// MARK: - Education Validation

extension Education {
    
    func validate() -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        results["school"] = school.isEmpty ? 
            .invalid(message: "Name der Schule/Institution ist erforderlich") : .valid
        results["degree"] = degree.isEmpty ? 
            .warning(message: "Abschluss oder Zertifizierung empfohlen") : .valid
        
        if let endDate = endDate {
            results["dates"] = endDate.validateEndDate(after: startDate)
        }
        
        return results
    }
}
