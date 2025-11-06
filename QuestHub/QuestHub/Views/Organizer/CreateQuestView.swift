//
//  CreateQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import SwiftUI

struct Challenge: Identifiable, Hashable {
    let id: UUID
    var title: String
    var details: String

    init(id: UUID = UUID(), title: String, details: String) {
        self.id = id
        self.title = title
        self.details = details
    }
}

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

    @State private var challenges: [Challenge] = []
    @State private var isPresentingCreateChallenge: Bool = false
    @State private var editingChallengeIndex: Int? = nil

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
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
                            TextField("(optional)", text: $subtitle)
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
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.tertiary.opacity(0.08))
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Challenges")
                                .font(.headline)
                            Spacer()
                            Button {
                                editingChallengeIndex = nil
                                isPresentingCreateChallenge = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 25))
                                    .tint(Color.qhPrimaryBlue)
                            }
                        }

                        if challenges.isEmpty {
                            Text("No challenges yet. Tap Add to create one.")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                                    Button {
                                        editingChallengeIndex = index
                                        isPresentingCreateChallenge = true
                                    } label: {
                                        HStack(alignment: .firstTextBaseline) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(challenge.title)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                if !challenge.details.isEmpty {
                                                    Text(challenge.details)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.tertiary)
                                        }
                                        .contentShape(Rectangle())
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)

                                    if index < challenges.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.tertiary.opacity(0.08))
                    )
                    
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
        .sheet(isPresented: $isPresentingCreateChallenge) {
            let existing = editingChallengeIndex.flatMap { challenges[$0] }
            CreateChallengeView(challenge: existing) { result in
                switch result {
                case .save(let newChallenge):
                    if let idx = editingChallengeIndex {
                        challenges[idx] = newChallenge
                    } else {
                        challenges.append(newChallenge)
                    }
                case .cancel:
                    break
                case .delete:
                    if let idx = editingChallengeIndex {
                        challenges.remove(at: idx)
                    }
                }
                editingChallengeIndex = nil
            }
            .presentationDetents([.medium, .large])
        }
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    CreateQuestView()
        .environmentObject(QHAuth())
}
