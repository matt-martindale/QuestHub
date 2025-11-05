//
//  Quest.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import Foundation

class Quest: Codable, Equatable {
    // Basic metadata
    var title: String
    var subtitle: String?
    var details: String?

    // Ownership and timing
    var createdAt: Date
    var creatorID: String

    // Access control
    var isLocked: Bool
    var password: String?

    init(
        title: String,
        subtitle: String? = nil,
        details: String? = nil,
        createdAt: Date = Date(),
        creatorID: String,
        isLocked: Bool = false,
        password: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.createdAt = createdAt
        self.creatorID = creatorID
        self.isLocked = isLocked
        self.password = password
    }

    static func == (lhs: Quest, rhs: Quest) -> Bool {
        return lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.details == rhs.details &&
        lhs.createdAt == rhs.createdAt &&
        lhs.creatorID == rhs.creatorID &&
        lhs.isLocked == rhs.isLocked &&
        lhs.password == rhs.password
    }
}
