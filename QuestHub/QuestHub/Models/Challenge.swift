//
//  Challenge.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/6/25.
//

import Foundation

enum ChallengeType: Hashable {
    case photo(PhotoData)
    case multipleChoice(MultipleChoiceData)
    case question(QuestionData)
}

struct Challenge: Codable, Identifiable, Hashable {
    let id: String?
    var title: String?
    var details: String?
    var points: Int?
    var completed: Bool?
    var challengeType: ChallengeType

    enum CodingKeys: String, CodingKey {
        case id, title, details, points, completed, challengeType
    }

    init(
        id: String? = nil,
        title: String? = nil,
        details: String? = nil,
        points: Int? = nil,
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

    // Provide resilient decoding: if 'challengeType' is missing, default to a sensible type.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.details = try container.decodeIfPresent(String.self, forKey: .details)
        self.points = try container.decodeIfPresent(Int.self, forKey: .points)
        self.completed = try container.decodeIfPresent(Bool.self, forKey: .completed)
        // Attempt to decode challengeType; if missing, fall back to a default
        if let decodedType = try container.decodeIfPresent(ChallengeType.self, forKey: .challengeType) {
            self.challengeType = decodedType
        } else {
            // Choose a safe default for legacy data lacking this field
            self.challengeType = .question(QuestionData())
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(details, forKey: .details)
        try container.encodeIfPresent(points, forKey: .points)
        try container.encodeIfPresent(completed, forKey: .completed)
        try container.encode(challengeType, forKey: .challengeType)
    }
}

extension ChallengeType: Codable {
    private enum CodingKeys: String, CodingKey { case kind, data }
    private enum Kind: String, Codable { case photo, multipleChoice, question }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .photo(let payload):
            try container.encode(Kind.photo, forKey: .kind)
            try container.encode(payload, forKey: .data)
        case .multipleChoice(let payload):
            try container.encode(Kind.multipleChoice, forKey: .kind)
            try container.encode(payload, forKey: .data)
        case .question(let payload):
            try container.encode(Kind.question, forKey: .kind)
            try container.encode(payload, forKey: .data)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .photo:
            let payload = try container.decode(PhotoData.self, forKey: .data)
            self = .photo(payload)
        case .multipleChoice:
            let payload = try container.decode(MultipleChoiceData.self, forKey: .data)
            self = .multipleChoice(payload)
        case .question:
            let payload = try container.decode(QuestionData.self, forKey: .data)
            self = .question(payload)
        }
    }
}

struct PhotoData: Codable, Hashable {
    var imageURL: String?
    var caption: String?
}

struct MultipleChoiceData: Codable, Hashable {
    var question: String?
    var answers: [String]?
    var correctAnswer: String?
}

struct QuestionData: Codable, Hashable {
    var question: String?
    var answer: String?
}

