//
//  AccountView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/10/25.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var auth: QHAuth

    var body: some View {
        List {
            if let user = auth.currentUser {
                Section {
                    LabeledContent("Account ID", value: user.id)
                    LabeledContent("Display Name", value: user.displayName ?? user.email ?? "anonymous")
                    LabeledContent("Email", value: user.email ?? "anonymous")
                    LabeledContent("Total Points", value: NumberFormatter.localizedString(from: NSNumber(value: user.totalPoints ?? 0), number: .none))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
}
