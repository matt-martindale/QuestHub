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

class Quest: Identifiable, Codable, Equatable, Hashable {
    // Stable identity for SwiftUI and persistence
    @DocumentID var id: String?
    var questCode: String? // Short format code for players to join

    // Basic metadata
    var imageURL: String?
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
    var requireSignIn: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case questCode
        case imageURL
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
        case requireSignIn
    }

    init(
        id: String? = nil,
        questCode: String? = nil,
        imageURL: String? = nil,
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
        password: String? = nil,
        requireSignIn: Bool = false
    ) {
        self.id = id
        self.questCode = questCode
        self.imageURL = imageURL
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
        self.requireSignIn = requireSignIn
    }

    static func == (lhs: Quest, rhs: Quest) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
