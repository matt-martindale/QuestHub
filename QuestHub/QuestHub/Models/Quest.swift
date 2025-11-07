//
//  Quest.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import Foundation
import FirebaseFirestore

class Quest: Identifiable, Codable, Equatable {
    // Stable identity for SwiftUI and persistence
    var id: String?

    // Basic metadata
    var title: String?
    var subtitle: String?
    var details: String?
    var partyLimit: Int?
    var challenges: [Challenge]?

    // Ownership and timing
    var createdAt: Date?
    var updatedAt: Date?
    var creatorID: String?
    var creatorDisplayName: String?

    // Access control
    var isLocked: Bool?
    var password: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case details
        case partyLimit
        case challenges
        case createdAt
        case updatedAt
        case creatorID
        case creatorDisplayName
        case isLocked
        case password
    }

    init(
        id: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        details: String? = nil,
        partyLimit: Int? = nil,
        challenges: [Challenge]? = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        creatorID: String? = nil,
        creatorDisplayName: String? = nil,
        isLocked: Bool = false,
        password: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.partyLimit = partyLimit
        self.challenges = challenges
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.creatorID = creatorID
        self.creatorDisplayName = creatorDisplayName
        self.isLocked = isLocked
        self.password = password
    }

    static func == (lhs: Quest, rhs: Quest) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.details == rhs.details &&
        lhs.partyLimit == rhs.partyLimit &&
        lhs.challenges == rhs.challenges &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt &&
        lhs.creatorID == rhs.creatorID &&
        lhs.creatorDisplayName == rhs.creatorDisplayName &&
        lhs.isLocked == rhs.isLocked &&
        lhs.password == rhs.password
    }
}

