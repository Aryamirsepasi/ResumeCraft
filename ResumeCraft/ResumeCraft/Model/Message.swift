//
//  Message.swift
//  Eris.
//
//  Created by Ignacio Palacio on 19/6/25.
//

import Foundation
import SwiftData

@Model
class Message: Identifiable {
    var id: UUID
    var content: String
    var role: Role
    var timestamp: Date
    var thread: Thread?
    
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }
    
    init(content: String, role: Role) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
    }
}
