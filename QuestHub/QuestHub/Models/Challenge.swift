//
//  Challenge.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/6/25.
//

import Foundation

struct Challenge: Identifiable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var points: Int
    var completed: Bool
    var challengeType: ChallengeType

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        points: Int,
        completed: Bool = false,
        challengeType: ChallengeType
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.points = points
        self.completed = completed
        self.challengeType = challengeType
    }

    enum ChallengeType: Hashable {
        case photo(PhotoData)
        case multipleChoice(MultipleChoiceData)
        case question(QuestionData)
    }
}

struct PhotoData: Hashable {
    var imageData: Data
    var caption: String?
}

struct MultipleChoiceData: Hashable {
    var prompt: String
    var anwers: [String]
    var correctAnswer: Int
}

struct QuestionData: Hashable {
    var prompt: String
    var answer: String
}
