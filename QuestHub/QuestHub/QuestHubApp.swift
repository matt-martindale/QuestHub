//
//  QuestHubApp.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/3/25.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAppCheck

@main
struct QuestHubApp: App {
    @StateObject private var auth = QHAuth()
    let persistenceController = PersistenceController.shared

    init() {
        FirebaseApp.configure()
        // Quick verification that Firebase App Check (App Attest) is working
        let appCheck = AppCheck.appCheck()
        appCheck.token(forcingRefresh: true) { token, error in
            if let error = error {
                print("[AppCheck] Failed to obtain token: \(error.localizedDescription)")
            } else if let token = token {
                print("[AppCheck] Successfully obtained App Check token. Expires at: \(token.expirationDate)")
            } else {
                print("[AppCheck] No token and no error returned.")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .gatedBySignIn()
                .environmentObject(auth)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

