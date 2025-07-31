import SwiftData
import Foundation

@Model
final class Resume {
    var updated: Date = Date()
    
    // One-to-one relationship
    @Relationship(deleteRule: .cascade, inverse: \PersonalInfo.resume)
    var personal: PersonalInfo?
    
    // One-to-many relationships with proper inverse
    @Relationship(deleteRule: .cascade, inverse: \WorkExperience.resume)
    var experiences: [WorkExperience] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Project.resume)
    var projects: [Project] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Skill.resume)
    var skills: [Skill] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Education.resume)
    var educations: [Education] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Extracurricular.resume)
    var extracurriculars: [Extracurricular] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Language.resume)
    var languages: [Language] = []
    
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
    var linkedIn: String? = nil
    var website: String? = nil
    var github: String? = nil
    
    // Back-reference to Resume
    var resume: Resume?
    
    init(firstName: String = "", lastName: String = "", email: String = "",
         phone: String = "", address: String = "", linkedIn: String? = nil,
         website: String? = nil, github: String? = nil) {
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
final class WorkExperience {
    var title: String = ""
    var company: String = ""
    var location: String = ""
    var startDate: Date = Date()
    var endDate: Date? = nil
    var isCurrent: Bool = false
    var details: String = ""
    var isVisible: Bool = true
    
    // Back-reference to Resume
    var resume: Resume?
    
    init(title: String = "", company: String = "", location: String = "",
         startDate: Date = Date(), endDate: Date? = nil, isCurrent: Bool = false,
         details: String = "") {
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
    var name: String = ""
    var details: String = ""
    var technologies: String = ""
    var link: String? = nil
    var isVisible: Bool = true
    
    // Back-reference to Resume
    var resume: Resume?
    
    init(name: String = "", details: String = "", technologies: String = "",
         link: String? = nil) {
        self.name = name
        self.details = details
        self.technologies = technologies
        self.link = link
    }
}

@Model
final class Skill {
    var name: String = ""
    var category: String = ""
    var isVisible: Bool = true
    
    // Back-reference to Resume
    var resume: Resume?
    
    init(name: String = "", category: String = "") {
        self.name = name
        self.category = category
    }
}

@Model
final class Education {
    var school: String = ""
    var degree: String = ""
    var field: String = ""
    var startDate: Date = Date()
    var endDate: Date? = nil
    var grade: String = ""
    var details: String = ""
    var isVisible: Bool = true
    
    // Back-reference to Resume
    var resume: Resume?
    
    init(school: String = "", degree: String = "", field: String = "",
         startDate: Date = Date(), endDate: Date? = nil, grade: String = "",
         details: String = "") {
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
    var title: String = ""
    var organization: String = ""
    var details: String = ""
    var isVisible: Bool = true
    
    // Back-reference to Resume
    var resume: Resume?
    
    init(title: String = "", organization: String = "", details: String = "") {
        self.title = title
        self.organization = organization
        self.details = details
    }
}

@Model
final class Language {
    var name: String = ""
    var proficiency: String = ""
    var isVisible: Bool = true
    
    // Back-reference to Resume
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
}

struct LanguageDTO: Decodable {
    let name: String
    let proficiency: String
    let isVisible: Bool
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
}
