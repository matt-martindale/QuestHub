import Foundation
import FirebaseFirestore

struct FirestoreService {
    private let db = Firestore.firestore()
    
    func fetchQuests(forUserID userID: String) async throws -> [Quest] {
        let collection = db.collection("quests")
        let snapshot = try await collection
            .whereField("creatorID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        var quests: [Quest] = []
        quests.reserveCapacity(snapshot.documents.count)
        for document in snapshot.documents {
            do {
                let quest = try document.data(as: Quest.self)
                quests.append(quest)
            } catch {
                continue
            }
        }
        // Defensive local sort by createdAt (newest first) in case some docs lack the field or server ordering can't be applied
        return quests.sorted { (lhs, rhs) in
            let l = (lhs.createdAt ?? Date.distantPast)
            let r = (rhs.createdAt ?? Date.distantPast)
            return l > r
        }
    }
    
    // Returns the human-friendly short questCode, not the Firestore document ID.
    @discardableResult
    func saveQuest(_ quest: Quest) async throws -> String {
        // We use Firestore auto-generated document IDs for storage, and store a human-friendly short code in `shortCode`.
        // `quest.id` is treated as the short code; `quest.documentID` (if present) is the Firestore document id.
        let questsCollection = db.collection("quests")
        let codesCollection = db.collection("questCodes")

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

        // Short code we expose to users
        var questCode = quest.questCode?.isEmpty == false ? quest.questCode! : IDGenerator.makeShortID()

        if isUpdating {
            // Update existing quest doc by Firestore documentID
            let docID = quest.id!
            let docRef = questsCollection.document(docID)

            // Fetch current to see existing shortCode (if any)
            let snapshot = try await docRef.getDocument()
            var oldquestCode: String? = nil
            if let data = snapshot.data(), let code = data["questCode"] as? String { oldquestCode = code }

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
                "questCode": questCode
            ]
            if let createdAt = quest.createdAt { updateData["createdAt"] = createdAt }

            // If short code changed, update the index in a batch (delete old, create new)
            if let old = oldquestCode, old != questCode {
                let batch = db.batch()
                // Update quest doc
                batch.setData(updateData, forDocument: docRef, merge: true)
                // Remove old index
                batch.deleteDocument(codesCollection.document(old))
                // Create new index
                batch.setData(["docID": docID, "updatedAt": Date()], forDocument: codesCollection.document(questCode), merge: false)
                try await batch.commit()
            } else {
                // No index change needed
                try await docRef.setData(updateData, merge: true)
                // Ensure index exists
                try await codesCollection.document(questCode).setData(["docID": docID, "updatedAt": Date()], merge: true)
            }
            return questCode
        } else {
            // Create new quest: retry on shortCode collisions
            let maxAttempts = 5
            for attempt in 0..<maxAttempts {
                // If not the first attempt, regenerate code
                if attempt > 0 { questCode = IDGenerator.makeShortID() }

                // First, check if the short code is free by trying to create the index doc
                let codeRef = codesCollection.document(questCode)
                let codeSnap = try await codeRef.getDocument()
                if codeSnap.exists {
                    continue // collision, try again
                }

                // Create the quest document with auto ID
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
                    "questCode": questCode,
                    "createdAt": Date()
                ]

                // Use `document()` to get an auto id, then set data so we can reference the id in the index
                let newDocRef = questsCollection.document()
                do {
                    try await newDocRef.setData(data)
                    // Create the index pointing shortCode -> docID
                    try await codeRef.setData(["docID": newDocRef.documentID, "createdAt": Date()])
                    return questCode
                } catch {
                    // If something failed (e.g., a race where the code doc got created), delete the created quest if needed and retry
                    // Best effort cleanup: check if quest doc exists and delete it if index creation failed
                    let createdSnap = try? await newDocRef.getDocument()
                    if let createdSnap, createdSnap.exists {
                        try? await newDocRef.delete()
                    }
                    continue
                }
            }
            throw NSError(domain: "FirestoreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create quest with unique short code"]) 
        }
    }
    
    func deleteQuest(withID id: String) async throws {
        let questsCollection = db.collection("quests")
        try await questsCollection.document(id).delete()
    }
}

