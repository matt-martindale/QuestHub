//
//  QHUser.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import Foundation

struct QHUser: Codable, Equatable, Identifiable {
    let id: String
    var email: String
    var displayName: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, email: String, displayName: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}
