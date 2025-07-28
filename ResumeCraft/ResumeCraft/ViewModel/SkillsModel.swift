//
//  SkillsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//


import SwiftUI

@Observable
final class SkillsModel {
    var items: [Skill]
    private weak var resume: Resume?

    init(resume: Resume) {
        self.resume = resume
        self.items = resume.skills
    }
    func add(_ skill: Skill) {
        skill.resume = resume
        items.append(skill)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}
