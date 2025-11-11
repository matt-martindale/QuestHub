//
//  AccountView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/10/25.
//

import SwiftUI

struct AccountSummary {
    var accountID: String
    var displayName: String
    var email: String
    var totalPoints: Int
}

struct AccountView: View {
    // In a real app, this would come from your model/view model.
    // Using a simple placeholder so the view previews nicely.
    var account: AccountSummary = .init(
        accountID: "A1B2-C3D4",
        displayName: "Matt Martindale",
        email: "matt@example.com",
        totalPoints: 1240
    )

    var body: some View {
        List {
            Section {
                LabeledContent("Account ID", value: account.accountID)
                LabeledContent("Display Name", value: account.displayName)
                LabeledContent("Email", value: account.email)
                LabeledContent("Total Points", value: NumberFormatter.localizedString(from: NSNumber(value: account.totalPoints), number: .decimal))
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
