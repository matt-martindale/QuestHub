//
//  Quest.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import Foundation
import FirebaseFirestore

enum QuestStatus: String, Codable {
    case active
    case paused
    case locked
}

class Quest: Identifiable, Codable, Equatable {
    // Stable identity for SwiftUI and persistence
    var id: String?

    // Basic metadata
    var title: String?
    var subtitle: String?
    var description: String?
    var maxPlayers: Int?
    var playersCount: Int?
    var challenges: [Challenge]?

    // Ownership and timing
    var createdAt: Date?
    var updatedAt: Date?
    var creatorID: String?
    var creatorDisplayName: String?

    // Access control
    var status: QuestStatus?
    var password: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case description
        case maxPlayers
        case playersCount
        case challenges
        case createdAt
        case updatedAt
        case creatorID
        case creatorDisplayName
        case status
        case password
    }

    init(
        id: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        description: String? = nil,
        maxPlayers: Int? = nil,
        playersCount: Int? = 0,
        challenges: [Challenge]? = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        creatorID: String? = nil,
        creatorDisplayName: String? = nil,
        status: QuestStatus? = .paused,
        password: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.maxPlayers = maxPlayers
        self.playersCount = playersCount
        self.challenges = challenges
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.creatorID = creatorID
        self.creatorDisplayName = creatorDisplayName
        self.status = status
        self.password = password
    }

    static func == (lhs: Quest, rhs: Quest) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.description == rhs.description &&
        lhs.maxPlayers == rhs.maxPlayers &&
        lhs.playersCount == rhs.playersCount &&
        lhs.challenges == rhs.challenges &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt &&
        lhs.creatorID == rhs.creatorID &&
        lhs.creatorDisplayName == rhs.creatorDisplayName &&
        lhs.status == rhs.status &&
        lhs.password == rhs.password
    }
}

