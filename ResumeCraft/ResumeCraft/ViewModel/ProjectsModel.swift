//
//  ProjectsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation

@Observable
final class ProjectsModel {
    var items: [Project]
    private weak var resume: Resume?

    init(resume: Resume) {
        self.resume = resume
        self.items = resume.projects
    }
    func add(_ project: Project) {
        project.resume = resume
        items.append(project)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    func update(_ project: Project, at index: Int) {
        guard items.indices.contains(index) else { return }
        project.resume = resume
        items[index] = project
    }
}
