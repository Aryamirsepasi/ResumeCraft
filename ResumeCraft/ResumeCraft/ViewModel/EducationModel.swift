//
//  EducationModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData

@Observable
final class EducationModel {
    private weak var resume: Resume?
    private let context: ModelContext

    init(resume: Resume, context: ModelContext) {
        self.resume = resume
        self.context = context
    }

    var items: [Education] {
        get { resume?.educations ?? [] }
        set { resume?.educations = newValue }
    }

    func add(_ edu: Education) {
        edu.resume = resume
        context.insert(edu)
        items.append(edu)
    }

    func remove(at offsets: IndexSet) {
        var copy = items
        copy.remove(atOffsets: offsets)
        items = copy
    }
}
