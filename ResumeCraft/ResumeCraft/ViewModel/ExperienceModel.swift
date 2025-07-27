//
//  ExperienceModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

@Observable
final class ExperienceModel {
    var items: [WorkExperience]
    private weak var resume: Resume?

    init(resume: Resume) {
        self.resume = resume
        self.items = resume.experiences
    }
    func add(_ exp: WorkExperience) {
        items.append(exp)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}

