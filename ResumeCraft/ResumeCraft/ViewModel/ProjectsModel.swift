//
//  ProjectsModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ProjectsModel {
  private weak var resume: Resume?
  private let context: ModelContext

  init(resume: Resume, context: ModelContext) {
    self.resume = resume
    self.context = context
  }

  var items: [Project] {
    get {
      (resume?.projects ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }
    set {
      for (idx, item) in newValue.enumerated() { item.orderIndex = idx }
      resume?.projects = newValue
    }
  }

  func add(_ project: Project) {
    project.resume = resume
    project.orderIndex = items.count
    context.insert(project)
    items.append(project)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }

  func update(_ project: Project, at index: Int) {
    guard items.indices.contains(index) else { return }
    project.resume = resume
    var copy = items
    copy[index] = project
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
