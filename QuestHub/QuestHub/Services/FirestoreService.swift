import Foundation
import FirebaseFirestore

struct FirestoreService {
    private let db = Firestore.firestore()
    
    func fetchQuests(forUserID userID: String) async throws -> [Quest] {
        let collection = db.collection("users").document(userID).collection("quests")
        let snapshot = try await collection.getDocuments()
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
        return quests
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
