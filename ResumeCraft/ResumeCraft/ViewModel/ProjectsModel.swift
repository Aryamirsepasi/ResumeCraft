//
//  ProjectsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class ProjectsModel {
    private weak var resume: Resume?
    private let context: ModelContext

    init(resume: Resume, context: ModelContext) {
        self.resume = resume
        self.context = context
    }

    var items: [Project] {
        get { resume?.projects ?? [] }
        set { resume?.projects = newValue }
    }

    func add(_ project: Project) {
        project.resume = resume
        context.insert(project)
        items.append(project)
    }

    func remove(at offsets: IndexSet) {
        var copy = items
        copy.remove(atOffsets: offsets)
        items = copy
    }

    func update(_ project: Project, at index: Int) {
        guard items.indices.contains(index) else { return }
        project.resume = resume
        var copy = items
        copy[index] = project
        items = copy
    }
}
