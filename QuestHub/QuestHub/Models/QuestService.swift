import Foundation
import FirebaseFirestore

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

    /// Joins a quest by updating both the quest doc and the user's joined quests, and creating a players subcollection doc.
    /// - Parameters:
    ///   - questId: The quest identifier
    ///   - userId: The current user's id
    ///   - userDisplayName: The user's display name
    ///   - maxPlayersEnforced: If true, will prevent joining when playersCount >= maxPlayers
    ///   - completion: Result callback
    func joinQuest(questId: String,
                   userId: String,
                   userDisplayName: String,
                   maxPlayersEnforced: Bool = true,
                   completion: @escaping (Result<Void, Error>) -> Void) {

        let qRef = questRef(questId)
        let uRef = userRef(userId)
        let pRef = playerRef(questId: questId, userId: userId)

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

            let currentPlayers = data["playerList"] as? [String] ?? []
            let playersCount = data["playersCount"] as? Int ?? 0
            let maxPlayers = data["maxPlayers"] as? Int ?? Int.max

            // Already joined? No-op for quest and user arrays; still ensure subcollection exists after transaction.
            if currentPlayers.contains(userId) {
                return nil
            }

            if maxPlayersEnforced && playersCount >= maxPlayers {
                errorPointer?.pointee = NSError(domain: "QuestService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Quest is full"]) 
                return nil
            }

            // Update quest doc
            transaction.updateData([
                "playerList": FieldValue.arrayUnion([userId]),
                "playersCount": FieldValue.increment(Int64(1))
            ], forDocument: qRef)

            // Update user doc: maintain an array of joined quest IDs
            transaction.setData([
                "quests": FieldValue.arrayUnion([questId])
            ], forDocument: uRef, merge: true)

            return nil
        }) { [weak self] (_, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            // After transaction, ensure the players subcollection doc exists/updated with metadata
            let entry = PlayerEntry(userId: userId, displayName: userDisplayName, joinedAt: Date())
            do {
                let encoded = try JSONEncoder().encode(entry)
                let json = try JSONSerialization.jsonObject(with: encoded, options: []) as? [String: Any] ?? [:]
                self?.playerRef(questId: questId, userId: userId).setData(json, merge: true) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        completion(.success(()))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}
