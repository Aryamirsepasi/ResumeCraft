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
    get {
      (resume?.experiences ?? []).sorted {
        $0.orderIndex < $1.orderIndex
      }
    }
    set {
      for (idx, item) in newValue.enumerated() { item.orderIndex = idx }
      resume?.experiences = newValue
    }
  }

  func add(_ exp: WorkExperience) {
    exp.resume = resume
    exp.orderIndex = items.count
    context.insert(exp)
    items.append(exp)
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
