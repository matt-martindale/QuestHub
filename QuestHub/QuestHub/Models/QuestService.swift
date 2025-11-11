import Foundation
import FirebaseFirestore
import FirebaseAuth

struct PlayerEntry: Codable {
    let userId: String
    let displayName: String
    let joinedAt: Date
}

final class QuestService {
    static let shared = QuestService()
    private init() {}

    private let db = Firestore.firestore()

    // Paths helpers
    private func questRef(_ questId: String) -> DocumentReference {
        db.collection("quests").document(questId)
    }

    private func userRef(_ userId: String) -> DocumentReference {
        db.collection("users").document(userId)
    }

    private func playerRef(questId: String, userId: String) -> DocumentReference {
        questRef(questId).collection("players").document(userId)
    }

    // MARK: - Quest methods
    @discardableResult
    func saveQuest(_ quest: Quest) async throws -> String {
        let questsCollection = db.collection("quests")

        // Helper to encode challenges
        let encodedChallenges: [[String: Any]] = (quest.challenges ?? []).map { ch in
            return [
                "id": ch.id ?? "",
                "title": ch.title ?? "",
                "details": ch.details ?? "",
                "points": ch.points ?? 0
            ]
        }

        // Determine if this is an update by presence of a Firestore documentID
        let isUpdating = (quest.id?.isEmpty == false)

        if isUpdating {
            // Update existing quest doc by Firestore documentID
            let docID = quest.id!
            let docRef = questsCollection.document(docID)

            // Preserve existing questCode on update; only use provided non-empty value
            var resolvedQuestCode: String = quest.questCode ?? ""
            if resolvedQuestCode.isEmpty {
                // Attempt to fetch existing code from Firestore to avoid overwriting
                let existing = try await docRef.getDocument()
                if let existingData = existing.data(), let storedCode = existingData["questCode"] as? String, !storedCode.isEmpty {
                    resolvedQuestCode = storedCode
                }
            }

            var updateData: [String: Any] = [
                "title": quest.title ?? "",
                "subtitle": quest.subtitle ?? "",
                "description": quest.description ?? "",
                "maxPlayers": quest.maxPlayers ?? 0,
                "creatorID": quest.creatorID ?? "",
                "creatorDisplayName": quest.creatorDisplayName ?? "",
                "status": quest.status?.rawValue ?? "inactive",
                "password": quest.password ?? "",
                "requireSignIn": quest.requireSignIn ?? false,
                "challenges": encodedChallenges,
                "updatedAt": Date(),
                "questCode": resolvedQuestCode
            ]
            if let createdAt = quest.createdAt { updateData["createdAt"] = createdAt }

            try await docRef.setData(updateData, merge: true)
            return resolvedQuestCode
        } else {
            // Create new quest document with an auto-generated ID
            let newQuestCode = quest.questCode?.isEmpty == false ? quest.questCode! : IDGenerator.makeShortID()

            var data: [String: Any] = [
                "title": quest.title ?? "",
                "subtitle": quest.subtitle ?? "",
                "description": quest.description ?? "",
                "maxPlayers": quest.maxPlayers ?? 0,
                "creatorID": quest.creatorID ?? "",
                "creatorDisplayName": quest.creatorDisplayName ?? "",
                "status": quest.status?.rawValue ?? "inactive",
                "password": quest.password ?? "",
                "requireSignIn": quest.requireSignIn ?? false,
                "challenges": encodedChallenges,
                "createdAt": Date(),
                "questCode": newQuestCode,
            ]

            let newDocRef = questsCollection.document()
            try await newDocRef.setData(data)
            return newQuestCode
        }
    }

    /// Deletes a quest document by its Firestore document ID.
    func deleteQuest(withID id: String) async throws {
        let questsCollection = db.collection("quests")
        try await questsCollection.document(id).delete()
    }
    
    /// Joins a quest by updating both the quest doc and the user's joined quests, and creating a players subcollection doc.
    /// - Parameters:
    ///   - questId: The Firestore quest document ID
    ///   - questCode: The human-readable quest code stored on the quest document
    ///   - userId: The current user's id
    ///   - userDisplayName: The user's display name
    ///   - maxPlayersEnforced: If true, will prevent joining when playersCount >= maxPlayers
    ///   - completion: Result callback
    func joinQuest(questId: String,
                   questCode: String,
                   userId: String,
                   userDisplayName: String,
                   maxPlayersEnforced: Bool = true,
                   completion: @escaping (Result<Void, Error>) -> Void) {

        // Use the Firestore document ID to reference the quest, and validate the questCode matches.
        let qRef = questRef(questId)
        let uRef = userRef(userId)
        let pRef = playerRef(questId: questId, userId: userId)

        guard let authUid = Auth.auth().currentUser?.uid, authUid == userId else {
            completion(.failure(NSError(domain: "QuestService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated as provided userId"])))
            return
        }

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(qRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard var data = snapshot.data() else {
                errorPointer?.pointee = NSError(domain: "QuestService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Quest not found"])
                return nil
            }

            // Validate that the provided questCode matches what's on the document
            if let storedCode = data["questCode"] as? String, !storedCode.isEmpty {
                if storedCode != questCode {
                    errorPointer?.pointee = NSError(domain: "QuestService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Quest code does not match this quest ID"])
                    return nil
                }
            }

            let playerSnapshot: DocumentSnapshot
            do {
                playerSnapshot = try transaction.getDocument(pRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // If the player doc already exists, do not increment count (no-op)
            if playerSnapshot.exists {
                return ["joined": false, "questId": questId, "questCode": questCode]
            }

            let playersCount = data["playersCount"] as? Int ?? 0
            let maxPlayers = data["maxPlayers"] as? Int ?? Int.max

            if maxPlayersEnforced && playersCount >= maxPlayers {
                errorPointer?.pointee = NSError(domain: "QuestService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Quest is full"])
                return nil
            }

            // Update quest doc
            transaction.updateData([
                "playersCount": FieldValue.increment(Int64(1))
            ], forDocument: qRef)

            return ["joined": true, "questId": questId, "questCode": questCode]
        }) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            let joined: Bool
            let questIdResult: String
            let questCodeResult: String
            if let dict = result as? [String: Any],
               let j = dict["joined"] as? Bool,
               let qid = dict["questId"] as? String,
               let qcode = dict["questCode"] as? String {
                joined = j
                questIdResult = qid
                questCodeResult = qcode
            } else {
                joined = true
                questIdResult = questId
                questCodeResult = questCode
            }

            // After transaction, if we actually joined, create the player doc and userQuests entry; otherwise, succeed without changes
            if joined {
                // Create/update player doc under quest
                pRef.setData([
                    "userId": userId,
                    "displayName": userDisplayName,
                    "points": 0
                ], merge: false) { err in
                    if let err = err {
                        completion(.failure(err))
                        return
                    }

                    // Populate userQuests ROOT collection with QuestID (documentID) and QuestCode (questCode)
                    let userQuestsRootRef = self.db.collection("userQuests").document("\(userId)_\(questIdResult)")
                    userQuestsRootRef.setData([
                        "userId": userId,
                        "questID": questIdResult,
                        "questCode": questCodeResult,
                        "joinedAt": Timestamp(date: Date())
                    ], merge: true) { uqErr in
                        if let uqErr = uqErr {
                            completion(.failure(uqErr))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Searches for a quest by code and returns the loaded Quest without joining.
    /// - Parameters:
    ///   - questCode: The human-readable quest code stored on the quest document
    ///   - completion: Result callback with the loaded Quest
    func searchQuest(byCode questCode: String,
                     completion: @escaping (Result<Quest, Error>) -> Void) {
        let trimmed = questCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(NSError(domain: "QuestService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Quest code is empty"])) )
            return
        }

        let query = db.collection("quests").whereField("questCode", isEqualTo: trimmed).limit(to: 1)
        query.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, let doc = snapshot.documents.first else {
                completion(.failure(NSError(domain: "QuestService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No quest found for code \(trimmed)"])) )
                return
            }

            let data = doc.data()

            // Map Firestore data to Quest model
            let quest = Quest()
            quest.id = doc.documentID
            quest.questCode = data["questCode"] as? String ?? trimmed
            quest.title = data["title"] as? String
            quest.subtitle = data["subtitle"] as? String
            quest.description = data["description"] as? String
            quest.maxPlayers = data["maxPlayers"] as? Int
            quest.playersCount = data["playersCount"] as? Int
            quest.creatorID = data["creatorID"] as? String
            quest.creatorDisplayName = data["creatorDisplayName"] as? String
            if let statusRaw = data["status"] as? String { quest.status = QuestStatus(rawValue: statusRaw) }
            if let createdTs = data["createdAt"] as? Timestamp { quest.createdAt = createdTs.dateValue() }
            if let updatedTs = data["updatedAt"] as? Timestamp { quest.updatedAt = updatedTs.dateValue() }

            completion(.success(quest))
        }
    }
    
    /// Searches for a quest by code (using document ID equality) and attempts to join it.
    /// Returns the loaded Quest on success.
    func searchAndJoin(questCode: String,
                       userId: String,
                       userDisplayName: String,
                       maxPlayersEnforced: Bool = true,
                       completion: @escaping (Result<Quest, Error>) -> Void) {
        let trimmed = questCode.trimmingCharacters(in: .whitespacesAndNewlines)
        searchQuest(byCode: trimmed) { [weak self] searchResult in
            switch searchResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let quest):
                guard let self = self, let questId = quest.id, let code = quest.questCode else {
                    completion(.failure(NSError(domain: "QuestService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid quest data"])) )
                    return
                }
                self.joinQuest(questId: questId,
                               questCode: code,
                               userId: userId,
                               userDisplayName: userDisplayName,
                               maxPlayersEnforced: maxPlayersEnforced) { joinResult in
                    switch joinResult {
                    case .success:
                        completion(.success(quest))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            }
        }
    }
}

