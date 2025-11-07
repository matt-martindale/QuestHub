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
    func saveQuest(questID: String?, userID: String, creatorDisplayName: String, title: String, subtitle: String, description: String, isLocked: Bool, password: String, challenges: [[String: Any]]
    ) async throws -> String {
        let isUpdating = (questID != nil)
        let id = questID ?? IDGenerator.makeShortID()

        var data: [String: Any] = [
            "id": id,
            "title": title,
            "subtitle": subtitle,
            "description": description,
            "creatorID": userID,
            "creatorDisplayName": creatorDisplayName,
            "isLocked": isLocked,
            "password": isLocked ? password : "",
            "challenges": challenges
        ]

        if isUpdating {
            data["updatedAt"] = Date()
        } else {
            data["createdAt"] = Date()
        }

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
