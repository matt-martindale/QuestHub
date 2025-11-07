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
        
        guard let authUid = Auth.auth().currentUser?.uid, authUid == userId else {
              completion(.failure(NSError(domain: "QuestService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated as provided userId"])))
              return
          }

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

            let playerSnapshot: DocumentSnapshot
            do {
                playerSnapshot = try transaction.getDocument(pRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // If the player doc already exists, do not increment count (no-op)
            if playerSnapshot.exists {
                return ["joined": false]
            }

            let playersCount = data["playersCount"] as? Int ?? 0
            let maxPlayers = data["maxPlayers"] as? Int ?? Int.max

            if maxPlayersEnforced && playersCount >= maxPlayers {
                errorPointer?.pointee = NSError(domain: "QuestService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Quest is full"]) 
                return nil
            }

            // Update quest doc
            transaction.updateData([
                "playersCount": FieldValue.increment(Int64(1))
            ], forDocument: qRef)

            // Update user doc: maintain an array of joined quest IDs
            transaction.setData([
                "quests": FieldValue.arrayUnion([questId])
            ], forDocument: uRef, merge: true)

            return ["joined": true]
        }) { [weak self] (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            let joined: Bool
            if let dict = result as? [String: Bool], let j = dict["joined"] {
                joined = j
            } else {
                joined = true // default to true if not provided
            }

            // After transaction, if we actually joined, create the player doc; otherwise, succeed without changes
            if joined {
                pRef.setData([
                    "userId": userId,
                    "displayName": userDisplayName
                ], merge: false) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                completion(.success(()))
            }
        }
    }
}

