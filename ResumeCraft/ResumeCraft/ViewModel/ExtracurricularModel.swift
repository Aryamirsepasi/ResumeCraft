//
//  ExtracurricularModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation

@Observable
final class ExtracurricularModel {
    var items: [Extracurricular]
    private weak var resume: Resume?

    init(resume: Resume) {
        self.resume = resume
        self.items = resume.extracurriculars
    }
    func add(_ activity: Extracurricular) {
        items.append(activity)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    func update(_ activity: Extracurricular, at index: Int) {
        guard items.indices.contains(index) else { return }
        items[index] = activity
    }
}
