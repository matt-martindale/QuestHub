//
//  Challenge.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/6/25.
//

import Foundation

struct Challenge: Codable, Identifiable, Hashable {
    let id: String?
    var title: String?
    var details: String?
    var points: Int?
    var completed: Bool?
//    var challengeType: ChallengeType

    init(
        id: String? = nil,
        title: String? = nil,
        details: String? = nil,
        points: Int? = nil,
        completed: Bool = false,
//        challengeType: ChallengeType
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.points = points
        self.completed = completed
//        self.challengeType = challengeType
    }

    enum ChallengeType: Codable, Hashable {
        case photo(PhotoData)
        case multipleChoice(MultipleChoiceData)
        case question(QuestionData)
    }
}

struct PhotoData: Codable, Hashable {
    var imageData: Data?
    var caption: String?
}

struct MultipleChoiceData: Codable, Hashable {
    var prompt: String?
    var anwers: [String]?
    var correctAnswer: Int?
}

struct QuestionData: Codable, Hashable {
    var prompt: String?
    var answer: String?
}
