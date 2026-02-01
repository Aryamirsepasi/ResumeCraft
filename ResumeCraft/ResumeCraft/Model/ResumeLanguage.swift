import Foundation
import SwiftUI

enum ResumeLanguage: String, CaseIterable, Identifiable, Hashable {
  case german = "de"
  case english = "en"

  var id: String { rawValue }

  static let defaultContent: ResumeLanguage = .german
  static let defaultOutput: ResumeLanguage = .german

  init?(code: String) {
    let normalized = code.lowercased()
    if normalized.hasPrefix("de") {
      self = .german
    } else if normalized.hasPrefix("en") {
      self = .english
    } else {
      return nil
    }
  }

  var locale: Locale {
    switch self {
    case .german:
      return Locale(identifier: "de_DE")
    case .english:
      return Locale(identifier: "en_US")
    }
  }

  var displayName: String {
    switch self {
    case .german:
      return String(localized: "language.german")
    case .english:
      return String(localized: "language.english")
    }
  }

  var fallback: ResumeLanguage {
    switch self {
    case .german: return .english
    case .english: return .german
    }
  }

  func resolvedValue(
    german: String,
    english: String?,
    fallback: ResumeLanguage?
  ) -> String {
    let englishValue = english ?? ""
    switch self {
    case .german:
      if !german.isEmpty { return german }
      if fallback == .english { return englishValue }
      return german
    case .english:
      if !englishValue.isEmpty { return englishValue }
      if fallback == .german { return german }
      return englishValue
    }
  }
}

extension Resume {
  var contentLanguage: ResumeLanguage {
    get { ResumeLanguage(code: contentLanguageCode) ?? .defaultContent }
    set { contentLanguageCode = newValue.rawValue }
  }

  var outputLanguage: ResumeLanguage {
    get { ResumeLanguage(code: outputLanguageCode) ?? .defaultOutput }
    set { outputLanguageCode = newValue.rawValue }
  }

  func ensureLanguageDefaults() {
    if contentLanguageCode.isEmpty {
      contentLanguageCode = ResumeLanguage.defaultContent.rawValue
    }
    if outputLanguageCode.isEmpty {
      outputLanguageCode = ResumeLanguage.defaultOutput.rawValue
    }
  }

  func miscellaneous(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(
      german: miscellaneous ?? "",
      english: miscellaneous_en,
      fallback: fallback
    )
  }

  func setMiscellaneous(_ value: String, for language: ResumeLanguage) {
    let sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    switch language {
    case .german:
      miscellaneous = sanitized.isEmpty ? nil : sanitized
    case .english:
      miscellaneous_en = sanitized.isEmpty ? nil : sanitized
    }
  }
}

extension PersonalInfo {
  func address(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: address, english: address_en, fallback: fallback)
  }

  func setAddress(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      address = value
    case .english:
      address_en = value
    }
  }
}

extension Summary {
  func text(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: text, english: text_en, fallback: fallback)
  }

  func setText(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      text = value
    case .english:
      text_en = value
    }
  }
}

extension WorkExperience {
  func title(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: title, english: title_en, fallback: fallback)
  }

  func company(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: company, english: company_en, fallback: fallback)
  }

  func location(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: location, english: location_en, fallback: fallback)
  }

  func details(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: details, english: details_en, fallback: fallback)
  }

  func setTitle(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      title = value
    case .english:
      title_en = value
    }
  }

  func setCompany(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      company = value
    case .english:
      company_en = value
    }
  }

  func setLocation(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      location = value
    case .english:
      location_en = value
    }
  }

  func setDetails(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      details = value
    case .english:
      details_en = value
    }
  }
}

extension Project {
  func name(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: name, english: name_en, fallback: fallback)
  }

  func details(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: details, english: details_en, fallback: fallback)
  }

  func technologies(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: technologies, english: technologies_en, fallback: fallback)
  }

  func setName(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      name = value
    case .english:
      name_en = value
    }
  }

  func setDetails(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      details = value
    case .english:
      details_en = value
    }
  }

  func setTechnologies(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      technologies = value
    case .english:
      technologies_en = value
    }
  }
}

extension Skill {
  func name(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: name, english: name_en, fallback: fallback)
  }

  func category(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: category, english: category_en, fallback: fallback)
  }

  func setName(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      name = value
    case .english:
      name_en = value
    }
  }

  func setCategory(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      category = value
    case .english:
      category_en = value
    }
  }
}

extension Education {
  func school(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: school, english: school_en, fallback: fallback)
  }

  func degree(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: degree, english: degree_en, fallback: fallback)
  }

  func field(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: field, english: field_en, fallback: fallback)
  }

  func details(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: details, english: details_en, fallback: fallback)
  }

  func grade(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: grade, english: grade_en, fallback: fallback)
  }

  func setSchool(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      school = value
    case .english:
      school_en = value
    }
  }

  func setDegree(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      degree = value
    case .english:
      degree_en = value
    }
  }

  func setField(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      field = value
    case .english:
      field_en = value
    }
  }

  func setDetails(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      details = value
    case .english:
      details_en = value
    }
  }

  func setGrade(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      grade = value
    case .english:
      grade_en = value
    }
  }
}

extension Extracurricular {
  func title(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: title, english: title_en, fallback: fallback)
  }

  func organization(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: organization, english: organization_en, fallback: fallback)
  }

  func details(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: details, english: details_en, fallback: fallback)
  }

  func setTitle(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      title = value
    case .english:
      title_en = value
    }
  }

  func setOrganization(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      organization = value
    case .english:
      organization_en = value
    }
  }

  func setDetails(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      details = value
    case .english:
      details_en = value
    }
  }
}

extension Language {
  func name(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: name, english: name_en, fallback: fallback)
  }

  func proficiency(for language: ResumeLanguage, fallback: ResumeLanguage? = nil) -> String {
    language.resolvedValue(german: proficiency, english: proficiency_en, fallback: fallback)
  }

  func setName(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      name = value
    case .english:
      name_en = value
    }
  }

  func setProficiency(_ value: String, for language: ResumeLanguage) {
    switch language {
    case .german:
      proficiency = value
    case .english:
      proficiency_en = value
    }
  }
}
