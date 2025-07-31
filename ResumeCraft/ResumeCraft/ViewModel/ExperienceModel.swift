//
//  ExperienceModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

@Observable
final class ExperienceModel {
  private weak var resume: Resume?

  init(resume: Resume) {
    self.resume = resume
  }

  var items: [WorkExperience] {
    get { resume?.experiences ?? [] }
    set { resume?.experiences = newValue }
  }

  func add(_ exp: WorkExperience) {
    exp.resume = resume
    items.append(exp)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    items = copy
  }
}
