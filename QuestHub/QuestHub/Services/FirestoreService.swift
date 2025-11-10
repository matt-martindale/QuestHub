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
    
    // Returns the human-friendly short questCode stored on the quest document.
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

        // Short code we expose to users; still stored on the quest document, but we no longer maintain a separate index
        let questCode = quest.questCode?.isEmpty == false ? quest.questCode! : IDGenerator.makeShortID()

        if isUpdating {
            // Update existing quest doc by Firestore documentID
            let docID = quest.id!
            let docRef = questsCollection.document(docID)

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

            try await docRef.setData(updateData, merge: true)
            return questCode
        } else {
            // Create new quest document with an auto-generated ID
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

            let newDocRef = questsCollection.document()
            try await newDocRef.setData(data)
            return questCode
        }
    }
    
    func deleteQuest(withID id: String) async throws {
        let questsCollection = db.collection("quests")
        try await questsCollection.document(id).delete()
    }
}
