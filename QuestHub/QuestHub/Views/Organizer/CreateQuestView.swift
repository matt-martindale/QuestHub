//
//  CreateQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import SwiftUI

struct CreateQuestView: View {
    @EnvironmentObject var auth: QHAuth
    @Environment(\.dismiss) private var dismiss
    @State private var path: [String] = []
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var descriptionText: String = ""
    @State private var isPasswordProtected: Bool = false
    @State private var password: String = ""
    @State private var showPasswordInfo: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading) {
                        Text("Title")
                        TextField("Ex: Thanksgiving scavenger hunt", text: $title)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.next)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Subtitle")
                        TextField("Ex: A Harvest of Clues! (optional)", text: $subtitle)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.next)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                        ZStack(alignment: .topLeading) {
                            if descriptionText.isEmpty {
                                Text("Add more details about your quest here.")
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }
                            TextEditor(text: $descriptionText)
                                .textInputAutocapitalization(.sentences)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .frame(minHeight: 120)
                        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isPasswordProtected) {
                            HStack(spacing: 6) {
                                Text("Password protect this quest")
                                Button {
                                    showPasswordInfo = true
                                } label: {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("When enabled, players must enter this password to join your quest.")
                                .popover(isPresented: $showPasswordInfo, arrowEdge: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Password protection")
                                            .font(.headline)
                                        Text("When enabled, players must enter this password to join your quest. Share the password only with the people you want to participate.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Button("Got it") { showPasswordInfo = false }
                                            .padding(.top, 8)
                                    }
                                    .padding()
                                    .frame(maxWidth: 320)
                                }
                            }
                        }
                        .padding(.trailing, 12)
                        .toggleStyle(.switch)

                        if isPasswordProtected {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Enter a password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .textContentType(.password)
                                    .padding(12)
                                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
            }
            .navigationTitle("Create Quest")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { route in
                if route == "details" {
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if let user = auth.currentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        SignedInUserMenu(user: user, allowSignOut: false)
                    }
                }
            }
            .padding()
        }
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    CreateQuestView()
}
