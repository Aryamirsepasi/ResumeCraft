//
//  ResumeEditorModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class ResumeEditorModel {
    // Holds the main resume entity
    private(set) var resume: Resume

    // Section editor viewmodels
    let personalModel: PersonalInfoModel
    let experienceModel: ExperienceModel
    let projectsModel: ProjectsModel
    let extracurricularModel: ExtracurricularModel
    let languageModel: LanguageModel

    private let context: ModelContext

    init(resume: Resume, context: ModelContext) {
        self.resume = resume
        self.context = context
        self.personalModel = PersonalInfoModel(personal: resume.personal ?? PersonalInfo())
        self.experienceModel = ExperienceModel(resume: resume)
        self.projectsModel = ProjectsModel(resume: resume)
        self.extracurricularModel = ExtracurricularModel(resume: resume)
        self.languageModel = LanguageModel(resume: resume)
    }

    func save() throws {
        // update relationships before saving
        resume.personal = personalModel.personal
        resume.experiences = experienceModel.items
        resume.projects = projectsModel.items
        resume.extracurriculars = extracurricularModel.items
        resume.languages = languageModel.items
        resume.updated = .now
        try context.save()
    }
}
