//
//  SkillsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class SkillsModel {
  private weak var resume: Resume?
  private let context: ModelContext

  init(resume: Resume, context: ModelContext) {
    self.resume = resume
    self.context = context
  }

  var items: [Skill] {
    get { (resume?.skills ?? []).sorted { $0.orderIndex < $1.orderIndex } }
    set {
      for (idx, item) in newValue.enumerated() { item.orderIndex = idx }
      resume?.skills = newValue
    }
  }

  func add(_ skill: Skill) {
    skill.resume = resume
    skill.orderIndex = items.count
    context.insert(skill)
    items.append(skill)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }

  func move(from source: IndexSet, to destination: Int) {
    var copy = items
    copy.move(fromOffsets: source, toOffset: destination)
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }
}
