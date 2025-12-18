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
            return .invalid(message: "Email is required")
        }
        
        if !trimmed.isValidEmail {
            return .invalid(message: "Please enter a valid email address")
        }
        
        // Check for professional email
        let unprofessionalDomains = ["hotmail.com", "aol.com", "yahoo.com"]
        if unprofessionalDomains.contains(where: { trimmed.lowercased().hasSuffix($0) }) {
            return .warning(message: "Consider using a professional email domain")
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
            return .warning(message: "Phone number recommended for recruiter contact")
        }
        
        let digitsOnly = trimmed.filter { $0.isNumber }
        
        if digitsOnly.count < 7 {
            return .invalid(message: "Phone number appears too short")
        }
        
        if digitsOnly.count > 15 {
            return .invalid(message: "Phone number appears too long")
        }
        
        return .valid
    }
    
    // MARK: - URL Validation
    
    /// Validates URL format
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    func validateURL(allowEmpty: Bool = true) -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return allowEmpty ? .valid : .invalid(message: "URL is required")
        }
        
        // Auto-add https if missing
        var urlString = trimmed
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard URL(string: urlString) != nil else {
            return .invalid(message: "Please enter a valid URL")
        }
        
        return .valid
    }
    
    // MARK: - LinkedIn Validation
    
    /// Validates LinkedIn profile URL
    var isValidLinkedIn: Bool {
        let lowercased = self.lowercased()
        return lowercased.contains("linkedin.com/in/") ||
               lowercased.contains("linkedin.com/pub/")
    }
    
    func validateLinkedIn() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "LinkedIn profile highly recommended (94% of recruiters use it)")
        }
        
        let lowercased = trimmed.lowercased()
        
        if !lowercased.contains("linkedin.com") {
            return .invalid(message: "Please enter a valid LinkedIn URL")
        }
        
        if !lowercased.contains("/in/") && !lowercased.contains("/pub/") {
            return .warning(message: "This doesn't look like a profile URL. Expected format: linkedin.com/in/yourname")
        }
        
        return .valid
    }
    
    // MARK: - GitHub Validation
    
    /// Validates GitHub profile URL
    var isValidGitHub: Bool {
        let lowercased = self.lowercased()
        return lowercased.contains("github.com/")
    }
    
    func validateGitHub() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .valid // GitHub is optional for non-tech roles
        }
        
        let lowercased = trimmed.lowercased()
        
        if !lowercased.contains("github.com") {
            return .invalid(message: "Please enter a valid GitHub URL")
        }
        
        // Check for repo URL vs profile URL
        let pathComponents = trimmed.components(separatedBy: "github.com/")
        if pathComponents.count > 1 {
            let path = pathComponents[1]
            if path.components(separatedBy: "/").filter({ !$0.isEmpty }).count > 1 {
                return .warning(message: "This looks like a repository URL. Use your profile URL instead")
            }
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
            return .invalid(message: "\(fieldName) is required")
        }
        
        if trimmed.count < 2 {
            return .invalid(message: "\(fieldName) is too short")
        }
        
        if trimmed.count > 50 {
            return .warning(message: "\(fieldName) is unusually long")
        }
        
        // Check for numbers in name
        if trimmed.contains(where: { $0.isNumber }) {
            return .warning(message: "\(fieldName) contains numbers")
        }
        
        return .valid
    }
    
    // MARK: - Summary Validation
    
    func validateSummary() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "A professional summary helps recruiters quickly understand your value")
        }
        
        let wordCount = trimmed.split(separator: " ").count
        
        if wordCount < 20 {
            return .warning(message: "Summary is too brief. Aim for 50-100 words")
        }
        
        if wordCount > 150 {
            return .warning(message: "Summary is too long. Keep it under 100 words for maximum impact")
        }
        
        // Check for first-person pronouns
        let hasFirstPerson = trimmed.lowercased().contains("i ") ||
                            trimmed.lowercased().contains("my ") ||
                            trimmed.lowercased().contains(" me ")
        
        if hasFirstPerson {
            return .warning(message: "Consider writing in third person or implied first person")
        }
        
        return .valid
    }
    
    // MARK: - Job Details Validation
    
    func validateJobDetails() -> ValidationResult {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .warning(message: "Add details about your responsibilities and achievements")
        }
        
        // Check for metrics
        let hasMetrics = trimmed.contains(where: { $0.isNumber }) ||
                        trimmed.contains("%") ||
                        trimmed.contains("$")
        
        if !hasMetrics {
            return .warning(message: "Consider adding quantifiable metrics (numbers, percentages)")
        }
        
        // Check for weak verbs
        let weakVerbs = ["responsible for", "helped", "worked on", "involved in", "assisted with"]
        let hasWeakVerbs = weakVerbs.contains(where: { trimmed.lowercased().contains($0) })
        
        if hasWeakVerbs {
            return .warning(message: "Use stronger action verbs (Led, Achieved, Drove, Built)")
        }
        
        return .valid
    }
}

// MARK: - PersonalInfo Validation Extension

extension PersonalInfo {
    
    /// Validates all personal info fields
    func validate() -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        results["firstName"] = firstName.validateName(fieldName: "First name")
        results["lastName"] = lastName.validateName(fieldName: "Last name")
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
            return .invalid(message: "End date must be after start date")
        }
        
        if self > Date() {
            return .warning(message: "End date is in the future")
        }
        
        return .valid
    }
    
    /// Validates that date is not too far in the past
    func validateReasonableDate(maxYearsAgo: Int = 50) -> ValidationResult {
        let calendar = Calendar.current
        let yearsAgo = calendar.date(byAdding: .year, value: -maxYearsAgo, to: Date())!
        
        if self < yearsAgo {
            return .warning(message: "Date seems unusually old")
        }
        
        if self > Date() {
            return .warning(message: "Date is in the future")
        }
        
        return .valid
    }
}

// MARK: - Skill Validation

extension Skill {
    
    func validate() -> ValidationResult {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(message: "Skill name is required")
        }
        
        if name.count > 50 {
            return .warning(message: "Skill name is too long")
        }
        
        return .valid
    }
}

// MARK: - WorkExperience Validation

extension WorkExperience {
    
    func validate() -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        results["title"] = title.isEmpty ? 
            .invalid(message: "Job title is required") : .valid
        results["company"] = company.isEmpty ? 
            .invalid(message: "Company name is required") : .valid
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
            .invalid(message: "Project name is required") : .valid
        results["details"] = details.isEmpty ? 
            .warning(message: "Add project description for better context") : .valid
        results["technologies"] = technologies.isEmpty ? 
            .warning(message: "List technologies used in this project") : .valid
        
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
            .invalid(message: "School/Institution name is required") : .valid
        results["degree"] = degree.isEmpty ? 
            .warning(message: "Degree or certification recommended") : .valid
        
        if let endDate = endDate {
            results["dates"] = endDate.validateEndDate(after: startDate)
        }
        
        return results
    }
}
