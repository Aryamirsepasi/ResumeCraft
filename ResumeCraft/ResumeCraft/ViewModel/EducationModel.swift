//
//  EducationModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

@Observable
final class EducationModel {
    var items: [Education]
    private weak var resume: Resume?

    init(resume: Resume) {
        self.resume = resume
        self.items = resume.educations
    }
    func add(_ edu: Education) {
        edu.resume = resume
        items.append(edu)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
}
