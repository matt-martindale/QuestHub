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
    private var joinedListener: ListenerRegistration?

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
    
    // Encodes an array of Challenge models into Firestore-friendly dictionaries
    private func encodeChallenges(_ challenges: [Challenge]) -> [[String: Any]] {
        return challenges.map { ch in
            let typeDict: [String: Any] = {
                switch ch.challengeType {
                case .photo(let payload):
                    return [
                        "kind": "photo",
                        "data": [
                            "imageURL": payload.imageURL ?? "",
                            "caption": payload.caption ?? "",
                            "prompt": payload.prompt ?? ""
                        ]
                    ]
                case .multipleChoice(let payload):
                    return [
                        "kind": "multipleChoice",
                        "data": [
                            "question": payload.question ?? "",
                            "answers": payload.answers ?? [],
                            "correctAnswer": payload.correctAnswer ?? ""
                        ]
                    ]
                case .question(let payload):
                    return [
                        "kind": "question",
                        "data": [
                            "question": payload.question ?? "",
                            "answer": payload.answer ?? ""
                        ]
                    ]
                case .prompt(let payload):
                    return [
                        "kind": "prompt",
                        "data": [
                            "prompt": payload.prompt ?? "",
                            "answer": payload.answer ?? ""
                        ]
                    ]
                }
            }()

            return [
                "id": ch.id ?? "",
                "title": ch.title ?? "",
                "details": ch.details ?? "",
                "points": ch.points ?? 0,
                "completed": ch.completed ?? false,
                "challengeType": typeDict
            ]
        }
    }

    // MARK: - Quest methods
    @discardableResult
    func saveQuest(_ quest: Quest) async throws -> String {
        let questsCollection = db.collection("quests")

        // Helper to encode challenges
        let encodedChallenges: [[String: Any]] = self.encodeChallenges(quest.challenges ?? [])

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

            let updateData: [String: Any] = [
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
                "questCode": resolvedQuestCode,
                "imageURL": quest.imageURL ?? ""
            ]
//            if let createdAt = quest.createdAt { updateData["createdAt"] = createdAt }

            try await docRef.setData(updateData, merge: true)
            return resolvedQuestCode
        } else {
            // Create new quest document with an auto-generated ID
            // Ensure the questCode is unique across the `quests` collection.
            let providedCode = (quest.questCode?.isEmpty == false) ? quest.questCode! : ""

            func generateCandidate() -> String { providedCode.isEmpty ? IDGenerator.makeShortID() : providedCode }

            var uniqueCode = generateCandidate()
            var attempts = 0
            let maxAttempts = 5
            while attempts < maxAttempts {
                // Check for existing quest with this code
                let snapshot = try await questsCollection.whereField("questCode", isEqualTo: uniqueCode).limit(to: 1).getDocuments()
                if snapshot.documents.isEmpty {
                    break
                }
                // If a provided code collides, only regenerate with random codes after the first failure
                uniqueCode = IDGenerator.makeShortID()
                attempts += 1
            }

            // If we somehow exhausted attempts and still collided, we still proceed with the last generated code; the chance of further collision is extremely low.
            let newQuestCode = uniqueCode

            let data: [String: Any] = [
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
                "updatedAt": Date(),
                "questCode": newQuestCode,
                "imageURL": quest.imageURL ?? ""
            ]

            let newDocRef = questsCollection.document()
            try await newDocRef.setData(data)
            return newQuestCode
        }
    }

    /// Deletes a quest document by its Firestore document ID.
    func deleteQuest(withID id: String) async throws {
        let questsCollection = db.collection("quests")
        let playersCollection = questsCollection.document(id).collection("players")

        // Fetch players docs
        let playersSnapshot = try await playersCollection.getDocuments()
        let playersDocs = playersSnapshot.documents

        // Delete in batches (max 500 operations per batch)
        let chunkSize = 450
        for chunkStart in stride(from: 0, to: playersDocs.count, by: chunkSize) {
            let chunk = playersDocs[chunkStart..<min(chunkStart + chunkSize, playersDocs.count)]
            let batch = db.batch()
            for doc in chunk {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
        }

        // Delete the quest doc
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
                   userId: String?,
                   userDisplayName: String,
                   maxPlayersEnforced: Bool = true,
                   completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure we have an authenticated user ID. If not provided or not signed in, sign in anonymously first.
        let proceedWithJoin: (_ resolvedUserId: String) -> Void = { resolvedUserId in
            // Use the Firestore document ID to reference the quest, and validate the questCode matches.
            let qRef = self.questRef(questId)
            let pRef = self.playerRef(questId: questId, userId: resolvedUserId)

            // Verify current auth matches resolvedUserId
            guard let authUid = Auth.auth().currentUser?.uid, authUid == resolvedUserId else {
                completion(.failure(NSError(domain: "QuestService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated as resolved userId"])) )
                return
            }

            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(qRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                guard let data = snapshot.data() else {
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
                    errorPointer?.pointee = NSError(domain: "QuestService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Maximum number of players has been reached."])
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
                        "userId": resolvedUserId,
                        "displayName": userDisplayName,
                        "points": 0
                    ], merge: false) { err in
                        if let err = err {
                            completion(.failure(err))
                            return
                        }

                        self.populateUserQuestsChallenges(qRef: qRef,
                                                          userId: resolvedUserId,
                                                          questId: questIdResult,
                                                          questCode: questCodeResult) { result in
                            switch result {
                            case .success:
                                completion(.success(()))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                } else {
                    completion(.success(()))
                }
            }
        }

        // Require a signed-in user. No anonymous sign-in fallback.
        if let providedUserId = userId, let currentUid = Auth.auth().currentUser?.uid, currentUid == providedUserId {
            proceedWithJoin(providedUserId)
        } else if let currentUid = Auth.auth().currentUser?.uid {
            // If already signed in (e.g., via your app's auth flow), proceed with current user
            proceedWithJoin(currentUid)
        } else {
            completion(.failure(NSError(domain: "QuestService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User must be signed in to join a quest"])) )
        }
    }
    
    /// Searches for a quest by code and returns the loaded Quest without joining.
    /// - Parameters:
    ///   - questCode: The human-readable quest code stored on the quest document
    ///   - completion: Result callback with the loaded Quest
    func searchQuest(byCode questCode: String,
                     completion: @escaping (Result<Quest, Error>) -> Void) {
        let trimmed = questCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
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
            quest.requireSignIn = data["requireSignIn"] as? Bool
            quest.password = data["password"] as? String
            quest.imageURL = data["imageURL"] as? String
            if let statusRaw = data["status"] as? String { quest.status = QuestStatus(rawValue: statusRaw) }
            if let createdTs = data["createdAt"] as? Timestamp { quest.createdAt = createdTs.dateValue() }
            if let updatedTs = data["updatedAt"] as? Timestamp { quest.updatedAt = updatedTs.dateValue() }

            completion(.success(quest))
        }
    }

    /// Async/await variant of `hasJoinedQuest(userId:questId:completion:)`.
    func hasJoinedQuest(userId: String, questId: String) async throws -> Bool {
        let docId = "\(userId)_\(questId)"
        let docRef = db.collection("userQuests").document(docId)
        let snapshot = try await docRef.getDocument()
        return snapshot.exists
    }

    deinit {
        joinedListener?.remove()
    }

    /// Starts listening to the joined quests for a given user id.
    /// - Parameters:
    ///   - uid: The user's uid to query against `userQuests`.
    ///   - onChange: Called on the main queue with the latest quests or an error message.
    func startListeningForJoinedQuests(uid: String, onChange: @escaping (_ quests: [Quest], _ errorMessage: String?) -> Void) {
        // Remove any existing listener before starting a new one
        joinedListener?.remove()

        let db = self.db
        joinedListener = db.collection("userQuests")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        onChange([], error.localizedDescription)
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        onChange([], nil)
                    }
                    return
                }

                // Extract quest IDs (support both "questID" and "QuestID")
                let questIds: [String] = documents.compactMap { doc in
                    let data = doc.data()
                    if let qid = data["questId"] as? String { return qid }
                    return nil
                }

                guard !questIds.isEmpty else {
                    DispatchQueue.main.async {
                        onChange([], nil)
                    }
                    return
                }

                // Firestore `in` queries support max 10 items; chunk IDs accordingly
                let chunkSize = 10
                let chunks: [[String]] = stride(from: 0, to: questIds.count, by: chunkSize).map { start in
                    Array(questIds[start..<min(start + chunkSize, questIds.count)])
                }

                var fetchedQuests: [Quest] = []
                var encounteredError: String?
                let group = DispatchGroup()

                for chunk in chunks {
                    group.enter()
                    db.collection("quests")
                        .whereField(FieldPath.documentID(), in: chunk)
                        .getDocuments { snap, err in
                            defer { group.leave() }

                            if let err = err {
                                let msg = err.localizedDescription
                                if let existing = encounteredError {
                                    encounteredError = existing + "\n" + msg
                                } else {
                                    encounteredError = msg
                                }
                                return
                            }

                            guard let docs = snap?.documents else { return }

                            let quests: [Quest] = docs.compactMap { doc in
                                do {
                                    return try doc.data(as: Quest.self)
                                } catch {
                                    print("Failed to decode Quest: \(error)")
                                    return nil
                                }
                            }

                            fetchedQuests.append(contentsOf: quests)
                        }
                }

                group.notify(queue: .main) {
                    let fetchedById: [String: Quest] = Dictionary(uniqueKeysWithValues: fetchedQuests.compactMap { q in
                        guard let qid = q.id, !qid.isEmpty else { return nil }
                        return (qid, q)
                    })

                    let ordered = questIds.compactMap { fetchedById[$0] }
                    onChange(ordered, encounteredError)
                }
            }
    }

    /// Stops listening to any active joined quests query.
    func stopListeningForJoinedQuests() {
        joinedListener?.remove()
        joinedListener = nil
    }
    
    /// Leaves a quest by removing the player's membership and the corresponding userQuests entry.
    /// - Parameters:
    ///   - questId: The Firestore quest document ID to leave
    ///   - userId: The current user's uid
    ///   - completion: Result callback
    func leaveQuest(questId: String,
                    userId: String,
                    completion: @escaping (Result<Void, Error>) -> Void) {
        // Verify current auth matches provided userId
        guard let currentUid = Auth.auth().currentUser?.uid, currentUid == userId else {
            completion(.failure(NSError(domain: "QuestService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated as provided userId"])) )
            return
        }

        let qRef = questRef(questId)
        let pRef = playerRef(questId: questId, userId: userId)
        let userQuestsRootRef = db.collection("userQuests").document("\(userId)_\(questId)")

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let questSnap: DocumentSnapshot
            do {
                questSnap = try transaction.getDocument(qRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let playerSnap: DocumentSnapshot
            do {
                playerSnap = try transaction.getDocument(pRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // If player doc doesn't exist, nothing to do
            guard playerSnap.exists else {
                return ["left": false]
            }

            // Decrement playersCount but not below zero
            let currentCount = (questSnap.data()? ["playersCount"] as? Int) ?? 0
            let newCount = max(currentCount - 1, 0)
            transaction.updateData(["playersCount": newCount], forDocument: qRef)

            // Delete player membership under quest
            transaction.deleteDocument(pRef)

            return ["left": true]
        }) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            // Remove userQuests root doc regardless of whether the transaction was a no-op
            userQuestsRootRef.delete { uqErr in
                if let uqErr = uqErr {
                    // We already removed membership; surface the error so caller can decide how to handle orphaned root doc
                    completion(.failure(uqErr))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Updates the quest's status using a raw string value.
    /// - Parameters:
    ///   - questId: The Firestore quest document ID to update.
    ///   - statusString: The new status raw value (case-insensitive) that maps to `QuestStatus`.
    ///   - completion: Completion handler returning the updated `QuestStatus` on success or an `Error` on failure.
    func updateQuestStatus(questId: String,
                           statusString: String,
                           completion: @escaping (Result<QuestStatus, Error>) -> Void) {
        // Normalize input and map to QuestStatus
        let normalized = statusString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let newStatus = QuestStatus(rawValue: normalized) else {
            completion(.failure(NSError(domain: "QuestService", code: 422, userInfo: [NSLocalizedDescriptionKey: "Invalid quest status: \(statusString)"])) )
            return
        }

        let ref = questRef(questId)
        ref.updateData([
            "status": newStatus.rawValue,
            "updatedAt": Date()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(newStatus))
            }
        }
    }
    
    /// Fetches the per-user challenges for a quest from userQuests and decodes them into `[Challenge]`.
    /// - Parameters:
    ///   - userId: The current user's uid
    ///   - questId: The Firestore quest document ID
    ///   - completion: Result callback with the decoded challenges array
    func fetchUserChallenges(userId: String,
                             questId: String,
                             completion: @escaping (Result<[Challenge], Error>) -> Void) {
        let docId = "\(userId)_\(questId)"
        let ref = db.collection("userQuests").document(docId)
        ref.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = snapshot?.data() else {
                completion(.success([]))
                return
            }
            do {
                if let raw = data["challenges"] as? [[String: Any]] {
                    let json = try JSONSerialization.data(withJSONObject: raw, options: [])
                    let decoder = JSONDecoder()
                    let decoded = try decoder.decode([Challenge].self, from: json)
                    completion(.success(decoded))
                } else {
                    completion(.success([]))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Populates userQuests ROOT document with per-user challenge progress copied from the quest
    private func populateUserQuestsChallenges(qRef: DocumentReference,
                                              userId: String,
                                              questId: String,
                                              questCode: String,
                                              completion: @escaping (Result<Void, Error>) -> Void) {
        let userQuestsRootRef = self.db.collection("userQuests").document("\(userId)_\(questId)")
        qRef.getDocument { qSnap, qErr in
            // Build challengeProgress dictionary keyed by challenge id
            var challengeProgress: [String: Any] = [:]
            if qErr == nil, let qSnap = qSnap, let qData = qSnap.data(), let rawChallenges = qData["challenges"] as? [[String: Any]] {
                for item in rawChallenges {
                    if let id = item["id"] as? String, !id.isEmpty {
                        challengeProgress[id] = [
                            "completed": false,
                            "completedAt": NSNull(),
                            "challengeResponse": ""
                        ]
                    }
                }
            }

            userQuestsRootRef.setData([
                "userId": userId,
                "questId": questId,
                "questCode": questCode,
                "joinedAt": Timestamp(date: Date()),
                "questPointsEarned": 0,
                "challengeProgress": challengeProgress
            ], merge: true) { uqErr in
                if let uqErr = uqErr {
                    completion(.failure(uqErr))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    /// Fetches the accumulated points for a specific user's quest progress (userQuests document) using a completion handler.
    /// - Parameters:
    ///   - userId: The user's uid
    ///   - questId: The Firestore quest document ID
    ///   - completion: Completion handler returning the integer points or an error
    func fetchUserQuestPoints(userId: String, questId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        self.computeCompletedChallengePoints(userId: userId, questId: questId) { result in
            switch result {
            case .success(let total):
                completion(.success(total))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Computes the total points for completed challenges in a user's quest progress (from userQuests document).
    /// - Parameters:
    ///   - userId: The user's uid
    ///   - questId: The Firestore quest document ID
    ///   - completion: Completion handler returning the computed integer points or an error
    private func computeCompletedChallengePoints(userId: String, questId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let userQuestDocId = "\(userId)_\(questId)"
        let userQuestRef = db.collection("userQuests").document(userQuestDocId)
        userQuestRef.getDocument { userQuestSnap, userQuestErr in
            if let userQuestErr = userQuestErr {
                completion(.failure(userQuestErr))
                return
            }
            guard let userQuestData = userQuestSnap?.data() else {
                completion(.success(0))
                return
            }
            // challengeProgress: [String: [String: Any]]
            let challengeProgress = userQuestData["challengeProgress"] as? [String: [String: Any]] ?? [:]
            // Build set of completed challenge IDs
            let completedChallengeIDs = Set<String>(challengeProgress.compactMap { (key, value) in
                if let completed = value["completed"] as? Bool, completed {
                    return key
                }
                return nil
            })

            let questRef = self.db.collection("quests").document(questId)
            questRef.getDocument { questSnap, questErr in
                if let questErr = questErr {
                    completion(.failure(questErr))
                    return
                }
                guard let questData = questSnap?.data(),
                      let challenges = questData["challenges"] as? [[String: Any]] else {
                    completion(.success(0))
                    return
                }
                var totalPoints = 0
                for challenge in challenges {
                    if let id = challenge["id"] as? String, completedChallengeIDs.contains(id) {
                        let points = challenge["points"] as? Int ?? 0
                        totalPoints += points
                    }
                }
                userQuestRef.updateData(["questPointsEarned": totalPoints]) { updateErr in
                    if let updateErr = updateErr {
                        completion(.failure(updateErr))
                    } else {
                        completion(.success(totalPoints))
                    }
                }
            }
        }
    }
}

