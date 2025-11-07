import Foundation
import FirebaseFirestore

struct FirestoreService {
    private let db = Firestore.firestore()
    
    func fetchQuests(forUserID userID: String) async throws -> [Quest] {
        let collection = db.collection("users").document(userID).collection("quests")
        let snapshot = try await collection
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
    
    @discardableResult
    func saveQuest(_ quest: Quest) async throws -> String {
        // Determine if this is an update based on presence of an id
        let isUpdating = (quest.id?.isEmpty == false)
        let id = quest.id ?? IDGenerator.makeShortID()

        let encodedChallenges: [[String: Any]] = (quest.challenges ?? []).map { ch in
            return [
                "id": ch.id ?? "",
                "title": ch.title ?? "",
                "details": ch.details ?? "",
                "points": ch.points ?? 0
            ]
        }

        // Build data dictionary from Quest
        var data: [String: Any] = [
            "id": id,
            "title": quest.title ?? "",
            "subtitle": quest.subtitle ?? "",
            "description": quest.description ?? "",
            "maxPlayers": quest.maxPlayers ?? 0,
            "creatorID": quest.creatorID ?? "",
            "creatorDisplayName": quest.creatorDisplayName ?? "",
            "status": quest.status?.rawValue ?? "inactive",
            "password": quest.password ?? "",
            "challenges": encodedChallenges
        ]

        // Preserve existing timestamps when possible; set the appropriate one now
        if isUpdating {
            data["updatedAt"] = Date()
            if let createdAt = quest.createdAt { data["createdAt"] = createdAt }
        } else {
            data["createdAt"] = Date()
        }

        let userID = quest.creatorID ?? ""
        let userQuests = db.collection("users").document(userID).collection("quests")
        let questsCollection = db.collection("quests")

        if isUpdating {
            try await userQuests.document(id).setData(data, merge: true)
            try await questsCollection.document(id).setData(data, merge: true)
        } else {
            try await userQuests.document(id).setData(data)
            try await questsCollection.document(id).setData(data)
        }

        return id
    }
}

