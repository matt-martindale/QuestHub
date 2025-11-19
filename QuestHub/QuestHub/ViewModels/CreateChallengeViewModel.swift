//
//  CreateChallengeViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/19/25.
//

import Foundation
import Combine

final class CreateChallengeViewModel: ObservableObject {
    @Published var title: String
    @Published var details: String

    // Type-specific editable state
    @Published var photoPrompt: String = ""
    @Published var mcQuestion: String = ""
    @Published var mcAnswers: [String] = ["", "", "", ""]
    @Published var mcCorrectAnswer: String = ""
    @Published var qQuestion: String = ""
    @Published var qAnswer: String = ""
    @Published var promptText: String = ""

    let existingChallenge: Challenge?
    let challengeType: ChallengeType?

    init(challengeType: ChallengeType?, challenge: Challenge?) {
        self.title = challenge?.title ?? ""
        self.details = challenge?.details ?? ""
        self.challengeType = challengeType
        self.existingChallenge = challenge

        switch challengeType {
        case .photo(let data):
            self.photoPrompt = data.prompt ?? ""
        case .multipleChoice(let data):
            self.mcQuestion = data.question ?? ""
            self.mcAnswers = data.answers ?? []
            self.mcCorrectAnswer = data.correctAnswer ?? ""
        case .question(let data):
            self.qQuestion = data.question ?? ""
            self.qAnswer = data.answer ?? ""
        case .prompt(let data):
            self.promptText = data.prompt ?? ""
        case .none:
            break
        }
    }

    var navigationTitle: String { existingChallenge == nil ? "New Challenge" : "Edit Challenge" }
    var typeTitle: String {
        switch challengeType {
        case .photo: return "Photo"
        case .multipleChoice: return "Multiple choice"
        case .question: return "Question"
        case .prompt: return "Prompt"
        case nil: return "Challenge"
        }
    }

    func buildChallenge() -> Challenge {
        let builtType: ChallengeType = {
            switch challengeType {
            case .photo:
                return .photo(PhotoData(prompt: photoPrompt))
            case .multipleChoice:
                let trimmed = mcAnswers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                let answers = trimmed
                let correct = mcCorrectAnswer
                return .multipleChoice(MultipleChoiceData(question: mcQuestion, answers: answers.isEmpty ? nil : answers, correctAnswer: correct.isEmpty ? nil : correct))
            case .question:
                return .question(QuestionData(question: qQuestion, answer: qAnswer))
            case .prompt:
                return .prompt(PromptData(prompt: promptText))
            case .none:
                return .question(QuestionData(question: "", answer: ""))
            }
        }()
        return Challenge(
            id: existingChallenge?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            points: 30,
            challengeType: builtType
        )
    }
}
