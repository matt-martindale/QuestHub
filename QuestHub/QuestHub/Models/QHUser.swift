//
//  QHUser.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import Foundation

struct QHUser: Codable, Equatable, Identifiable {
    let id: String
    var email: String?
    var displayName: String?
    var createdAt: Date
    var totalPoints: Int?

    init(id: String = UUID().uuidString, email: String? = nil, displayName: String? = nil, createdAt: Date = Date(), totalPoints: Int? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.totalPoints = totalPoints
    }
}
