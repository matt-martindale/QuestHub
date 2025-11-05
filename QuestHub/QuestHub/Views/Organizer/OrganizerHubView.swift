//
//  OrganizerHubView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct OrganizerHubView: View {
    @EnvironmentObject var auth: QHAuth
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            if let user = auth.currentUser {
                Text("Welcome, \(user.displayName?.isEmpty == false ? user.displayName! : user.email)")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("User ID: \(user.id)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    auth.signOut()
                    dismiss()
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            } else {
                Text("No user is currently signed in.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Organizer Hub")
//        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OrganizerHubView()
        .environmentObject(QHAuth())
}

