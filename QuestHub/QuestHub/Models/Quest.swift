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
    @DocumentID var id: String?

    // Basic metadata
    var title: String
    var subtitle: String?
    var details: String?
    var partyLimit: Int

    // Ownership and timing
    var createdAt: Date
    var creatorID: String

    // Access control
    var isLocked: Bool
    var password: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case details
        case partyLimit
        case createdAt
        case creatorID
        case isLocked
        case password
    }

    init(
        id: String? = nil,
        title: String,
        subtitle: String? = nil,
        details: String? = nil,
        partyLimit: Int,
        createdAt: Date = Date(),
        creatorID: String,
        isLocked: Bool = false,
        password: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.partyLimit = partyLimit
        self.createdAt = createdAt
        self.creatorID = creatorID
        self.isLocked = isLocked
        self.password = password
    }

    static func == (lhs: Quest, rhs: Quest) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.details == rhs.details &&
        lhs.partyLimit == rhs.partyLimit &&
        lhs.createdAt == rhs.createdAt &&
        lhs.creatorID == rhs.creatorID &&
        lhs.isLocked == rhs.isLocked &&
        lhs.password == rhs.password
    }
}

