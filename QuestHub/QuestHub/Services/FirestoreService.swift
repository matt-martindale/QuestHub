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
    
    func createMockQuest(forUserID userID: String) async throws {
        let collection = db.collection("users").document(userID).collection("quests")
        let mock: [String: Any] = [
            "title": "Demo Quest",
            "subtitle": "First steps",
            "details": "This is a mock quest created for testing.",
            "createdAt": Date(),
            "creatorID": userID,
            "isLocked": false
        ]
        _ = try await collection.addDocument(data: mock)
    }
}
