import SwiftData
import Foundation

@Model
final class Resume {
    var updated: Date = Date()
    var contentLanguageCode: String = ResumeLanguage.defaultContent.rawValue
    var outputLanguageCode: String = ResumeLanguage.defaultOutput.rawValue

    // One-to-one relationships
    @Relationship(deleteRule: .cascade, inverse: \PersonalInfo.resume)
    var personal: PersonalInfo?

    @Relationship(deleteRule: .cascade, inverse: \Summary.resume)
    var summary: Summary?

    var miscellaneous: String? = nil
    var miscellaneous_en: String? = nil

    // One-to-many relationships (must be optional for CloudKit)
    @Relationship(deleteRule: .cascade, inverse: \WorkExperience.resume)
    var experiences: [WorkExperience]?

    @Relationship(deleteRule: .cascade, inverse: \Project.resume)
    var projects: [Project]?

    @Relationship(deleteRule: .cascade, inverse: \Skill.resume)
    var skills: [Skill]?

    @Relationship(deleteRule: .cascade, inverse: \Education.resume)
    var educations: [Education]?

    @Relationship(deleteRule: .cascade, inverse: \Extracurricular.resume)
    var extracurriculars: [Extracurricular]?

    @Relationship(deleteRule: .cascade, inverse: \Language.resume)
    var languages: [Language]?

    init() {
        self.updated = Date()
    }
}

@Model
final class PersonalInfo {
  var firstName: String = ""
  var lastName: String = ""
  var email: String = ""
  var phone: String = ""
  var address: String = ""
  var address_en: String? = nil
  var linkedIn: String? = nil
  var website: String? = nil
  var github: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(
    firstName: String = "",
    lastName: String = "",
    email: String = "",
    phone: String = "",
    address: String = "",
    linkedIn: String? = nil,
    website: String? = nil,
    github: String? = nil
  ) {
    self.firstName = firstName
    self.lastName = lastName
    self.email = email
    self.phone = phone
    self.address = address
    self.linkedIn = linkedIn
    self.website = website
    self.github = github
  }
}

@Model
final class Summary {
  var text: String = ""
  var text_en: String? = nil
  var text_de: String? = nil
  var isVisible: Bool = true
  @Relationship
  var resume: Resume?

  init(text: String = "", isVisible: Bool = true) {
    self.text = text
    self.isVisible = isVisible
  }
}

@Model
final class WorkExperience {
  // Ordering
  var orderIndex: Int = 0

  // English fields
  var title: String = ""
  var company: String = ""
  var location: String = ""
  var startDate: Date = Date()
  var endDate: Date? = nil
  var isCurrent: Bool = false
  var details: String = ""
  var isVisible: Bool = true

  // English translation fields
  var title_en: String? = nil
  var company_en: String? = nil
  var location_en: String? = nil
  var details_en: String? = nil

  // Legacy translation fields (deprecated; kept for migration)
  var title_de: String? = nil
  var company_de: String? = nil
  var location_de: String? = nil
  var details_de: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(
    title: String = "",
    company: String = "",
    location: String = "",
    startDate: Date = Date(),
    endDate: Date? = nil,
    isCurrent: Bool = false,
    details: String = ""
  ) {
    self.title = title
    self.company = company
    self.location = location
    self.startDate = startDate
    self.endDate = endDate
    self.isCurrent = isCurrent
    self.details = details
  }
}

@Model
final class Project {
  // Ordering
  var orderIndex: Int = 0

  // English fields
  var name: String = ""
  var details: String = ""
  var technologies: String = ""
  var link: String? = nil
  var isVisible: Bool = true

  // English translation fields
  var name_en: String? = nil
  var details_en: String? = nil
  var technologies_en: String? = nil

  // Legacy translation fields (deprecated; kept for migration)
  var name_de: String? = nil
  var details_de: String? = nil
  var technologies_de: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(
    name: String = "",
    details: String = "",
    technologies: String = "",
    link: String? = nil
  ) {
    self.name = name
    self.details = details
    self.technologies = technologies
    self.link = link
  }
}

@Model
final class Skill {
  // Ordering
  var orderIndex: Int = 0

  var name: String = ""
  var category: String = ""
  var isVisible: Bool = true

  // English translation fields
  var name_en: String? = nil
  var category_en: String? = nil

  // Legacy translation fields (deprecated; kept for migration)
  var name_de: String? = nil
  var category_de: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(name: String = "", category: String = "") {
    self.name = name
    self.category = category
  }
}

@Model
final class Education {
  // Ordering
  var orderIndex: Int = 0

  var school: String = ""
  var degree: String = ""
  var field: String = ""
  var startDate: Date = Date()
  var endDate: Date? = nil
  var grade: String = ""
  var details: String = ""
  var isVisible: Bool = true

  // English translation fields
  var school_en: String? = nil
  var degree_en: String? = nil
  var field_en: String? = nil
  var grade_en: String? = nil
  var details_en: String? = nil

  // Legacy translation fields (deprecated; kept for migration)
  var school_de: String? = nil
  var degree_de: String? = nil
  var field_de: String? = nil
  var details_de: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(
    school: String = "",
    degree: String = "",
    field: String = "",
    startDate: Date = Date(),
    endDate: Date? = nil,
    grade: String = "",
    details: String = ""
  ) {
    self.school = school
    self.degree = degree
    self.field = field
    self.startDate = startDate
    self.endDate = endDate
    self.grade = grade
    self.details = details
  }
}

@Model
final class Extracurricular {
  // Ordering
  var orderIndex: Int = 0

  var title: String = ""
  var organization: String = ""
  var details: String = ""
  var isVisible: Bool = true

  // English translation fields
  var title_en: String? = nil
  var organization_en: String? = nil
  var details_en: String? = nil

  // Legacy translation fields (deprecated; kept for migration)
  var title_de: String? = nil
  var organization_de: String? = nil
  var details_de: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(title: String = "", organization: String = "", details: String = "") {
    self.title = title
    self.organization = organization
    self.details = details
  }
}

@Model
final class Language {
  // Ordering
  var orderIndex: Int = 0

  var name: String = ""
  var proficiency: String = ""
  var isVisible: Bool = true

  // English translation fields
  var name_en: String? = nil
  var proficiency_en: String? = nil

  // Legacy translation fields (deprecated; kept for migration)
  var name_de: String? = nil
  var proficiency_de: String? = nil

  // Back-reference to Resume
  @Relationship
  var resume: Resume?

  init(name: String = "", proficiency: String = "") {
    self.name = name
    self.proficiency = proficiency
  }
}

// DTOs for Decoding
struct PersonalInfoDTO: Decodable {
  let firstName: String
  let lastName: String
  let email: String
  let phone: String
  let address: String
  let linkedIn: String?
  let website: String?
  let github: String?
}

struct SkillDTO: Decodable {
  let name: String
  let category: String
  let isVisible: Bool

  // Legacy translation fields (deprecated; kept for migration)
  let name_de: String?
  let category_de: String?
}

struct WorkExperienceDTO: Decodable {
  let title: String
  let company: String
  let location: String
  let startDate: Date
  let endDate: Date?
  let isCurrent: Bool
  let details: String
  let isVisible: Bool
}

struct ProjectDTO: Decodable {
  let name: String
  let details: String
  let technologies: String
  let link: String?
  let isVisible: Bool
}

struct ExtracurricularDTO: Decodable {
  let title: String
  let organization: String
  let details: String
  let isVisible: Bool

  // Legacy translation fields (deprecated; kept for migration)
  let title_de: String?
  let organization_de: String?
  let details_de: String?
}

struct LanguageDTO: Decodable {
  let name: String
  let proficiency: String
  let isVisible: Bool

  // Legacy translation fields (deprecated; kept for migration)
  let name_de: String?
  let proficiency_de: String?
}

struct EducationDTO: Decodable {
  let school: String
  let degree: String
  let field: String
  let startDate: Date
  let endDate: Date?
  let grade: String
  let details: String
  let isVisible: Bool

  // Legacy translation fields (deprecated; kept for migration)
  let school_de: String?
  let degree_de: String?
  let field_de: String?
  let details_de: String?
}
