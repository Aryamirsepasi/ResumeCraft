import SwiftData
import Foundation

@Model
final class Resume {
    @Attribute(.unique) var id: UUID
    var personal: PersonalInfo?
    @Relationship(deleteRule: .cascade, inverse: \WorkExperience.resume) var experiences: [WorkExperience]
    @Relationship(deleteRule: .cascade, inverse: \Project.resume) var projects: [Project]
    @Relationship(deleteRule: .cascade, inverse: \Extracurricular.resume) var extracurriculars: [Extracurricular]
    @Relationship(deleteRule: .cascade, inverse: \Language.resume) var languages: [Language]
    var created: Date
    var updated: Date

    init(id: UUID = UUID(), created: Date = .now, updated: Date = .now) {
        self.id = id
        self.created = created
        self.updated = updated
        self.experiences = []
        self.projects = []
        self.extracurriculars = []
        self.languages = []
    }
}

@Model
final class PersonalInfo {
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var address: String
    var linkedIn: String?
    var website: String?
    var github: String?
    var resume: Resume?

    init(firstName: String = "", lastName: String = "", email: String = "", phone: String = "", address: String = "", linkedIn: String? = nil, website: String? = nil, github: String? = nil) {
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
    var title: String
    var company: String
    var location: String
    var startDate: Date
    var endDate: Date?
    var isCurrent: Bool
    var details: String
    var resume: Resume?

    init(title: String = "", company: String = "", location: String = "", startDate: Date = .now, endDate: Date? = nil, isCurrent: Bool = false, details: String = "") {
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
    var name: String
    var dscription: String
    var technologies: String
    var link: String?
    var resume: Resume?

    init(name: String = "", description: String = "", technologies: String = "", link: String? = nil) {
        self.name = name
        self.dscription = description
        self.technologies = technologies
        self.link = link
    }
}

@Model
final class Extracurricular {
    var title: String
    var organization: String
    var dscription: String
    var resume: Resume?

    init(title: String = "", organization: String = "", description: String = "") {
        self.title = title
        self.organization = organization
        self.dscription = description
    }
}

@Model
final class Language {
    var name: String
    var proficiency: String
    var resume: Resume?

    init(name: String = "", proficiency: String = "") {
        self.name = name
        self.proficiency = proficiency
    }
}
