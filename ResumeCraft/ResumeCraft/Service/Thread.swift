//
//  Thread.swift
//  Eris.
//
//  Created by Ignacio Palacio on 19/6/25.
//

import Foundation
import SwiftData

@Model
class Thread: Identifiable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \Message.thread)
    var messages: [Message] = []
    
    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var lastMessage: Message? {
        sortedMessages.last
    }
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
    }
}