//
//  SkillsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

@Observable
final class SkillsModel {
  private weak var resume: Resume?

  init(resume: Resume) {
    self.resume = resume
  }

  var items: [Skill] {
    get { resume?.skills ?? [] }
    set { resume?.skills = newValue }
  }

  func add(_ skill: Skill) {
    skill.resume = resume
    items.append(skill)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    items = copy
  }
}
