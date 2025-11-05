import Foundation
import FirebaseFirestore

struct FirestoreService {
    private let db = Firestore.firestore()
    
    private func decodeQuest(from dictionary: [String: Any]) throws -> Quest {
        // Firestore returns [String: Any]; convert to JSON data and decode with JSONDecoder
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let decoder = JSONDecoder()
        // If your Quest has date fields stored as timestamps or ISO strings, configure the decoder here
        return try decoder.decode(Quest.self, from: data)
    }

    func fetchQuests(forUserID userID: String) async throws -> [Quest] {
        let collection = db.collection("users").document(userID).collection("quests")
        let snapshot = try await collection.getDocuments()
        var quests: [Quest] = []
        quests.reserveCapacity(snapshot.documents.count)
        for document in snapshot.documents {
            do {
                var data = document.data()
                // Optionally inject the document ID if Quest expects it under a specific key
                // e.g., data["id"] = document.documentID
                let quest = try decodeQuest(from: data)
                quests.append(quest)
            } catch {
                // Skip malformed documents; in a real app you might log this
                continue
            }
        }
        return quests
    }
}
