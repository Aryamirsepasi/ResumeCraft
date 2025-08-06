//
//  ExperienceModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData

@Observable
final class ExperienceModel {
    private weak var resume: Resume?
    private let context: ModelContext

    init(resume: Resume, context: ModelContext) {
        self.resume = resume
        self.context = context
    }

    var items: [WorkExperience] {
        get { resume?.experiences ?? [] }
        set { resume?.experiences = newValue }
    }

    func add(_ exp: WorkExperience) {
        exp.resume = resume
        context.insert(exp)
        items.append(exp)
    }

    func remove(at offsets: IndexSet) {
        var copy = items
        copy.remove(atOffsets: offsets)
        items = copy
    }
}
