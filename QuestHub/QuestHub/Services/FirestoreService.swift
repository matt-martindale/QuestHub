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
    
    func createMockQuest(forUser user: QHUser) async throws {
        let collection = db.collection("users").document(user.id).collection("quests")
        let mock: [String: Any] = [
            "title": "Demo Quest",
            "subtitle": "First steps",
            "details": "This is a mock quest created for testing.",
            "partyLimit": 50,
            "createdAt": Date(),
            "creatorID": user.id,
            "creatorDisplayName": user.displayName ?? user.email ?? "anonymous",
            "isLocked": false,
            "password": "password"
        ]
        _ = try await collection.addDocument(data: mock)
    }
}
