//
//  UserQuest.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/20/25.
//

import Foundation

struct UserQuest: Codable, Identifiable, Hashable {
    let id: String // userId_questId
    let questId: String?
    let userId: String?
    let questCode: String?
    let points: Int?
    let joinedAt: Date?
    let challengeProgress: [String : ChallengeProgress]?
}

struct ChallengeProgress: Codable, Hashable {
    let completed: Bool?
    let challengePoints: Int?
    let completedAt: Date?
    let challengeResponse: String?
}
