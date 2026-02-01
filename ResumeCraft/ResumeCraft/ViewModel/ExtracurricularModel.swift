//
//  ExtracurricularModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ExtracurricularModel {
  private weak var resume: Resume?
  private let context: ModelContext

  init(resume: Resume, context: ModelContext) {
    self.resume = resume
    self.context = context
  }

  var items: [Extracurricular] {
    get {
      (resume?.extracurriculars ?? []).sorted {
        $0.orderIndex < $1.orderIndex
      }
    }
    set {
      for (idx, item) in newValue.enumerated() { item.orderIndex = idx }
      resume?.extracurriculars = newValue
    }
  }

  func add(_ activity: Extracurricular) {
    activity.resume = resume
    activity.orderIndex = items.count
    context.insert(activity)
    items.append(activity)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }

  func update(_ activity: Extracurricular, at index: Int) {
    guard items.indices.contains(index) else { return }
    activity.resume = resume
    var copy = items
    copy[index] = activity
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
