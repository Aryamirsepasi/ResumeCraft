//
//  SkillsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData

@Observable
final class SkillsModel {
    private weak var resume: Resume?
    private let context: ModelContext

    init(resume: Resume, context: ModelContext) {
        self.resume = resume
        self.context = context
    }

    var items: [Skill] {
        get { resume?.skills ?? [] }
        set { resume?.skills = newValue }
    }

    func add(_ skill: Skill) {
        skill.resume = resume
        context.insert(skill)
        items.append(skill)
    }

    func remove(at offsets: IndexSet) {
        var copy = items
        copy.remove(atOffsets: offsets)
        items = copy
    }
}
