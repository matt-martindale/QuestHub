//
//  AccountView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/10/25.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: QHAuth

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                if let user = auth.currentUser {
                    Section {
                        LabeledContent("Display Name", value: user.displayName ?? user.email ?? "anonymous")
                        LabeledContent("Email", value: user.email ?? "anonymous")
                        LabeledContent("Total Points", value: NumberFormatter.localizedString(from: NSNumber(value: user.totalPoints ?? 0), number: .none))
                    }
                }
            }
            .listStyle(.insetGrouped)

            if let user = auth.currentUser {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account ID: \(user.id)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    Text("Version: \(appVersion) (\(appBuild))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                }
                .background(Color.clear)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
}
