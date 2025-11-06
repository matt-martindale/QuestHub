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
            List {
                // Section 1 — Quest info
                Section {
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

                // Section 2 — Challenges
                Section(header: Text("Challenges").font(.headline)) {
                    ForEach(challenges.indices, id: \.self) { index in
                        let challenge = challenges[index]
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
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove { indices, newOffset in
                        challenges.move(fromOffsets: indices, toOffset: newOffset)
                    }

                    Button {
                        editingChallengeIndex = nil
                        isPresentingCreateChallenge = true
                    } label: {
                        Label("Add challenge", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.qhPrimaryBlue)
                    }
                    .buttonStyle(.plain)
                }

                // Section 3 — Password
                Section {
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
                            .sheet(isPresented: $showPasswordInfo) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Spacer()
                                        Button("Done") { showPasswordInfo = false }
                                            .padding()
                                            .bold()
                                    }
                                    Spacer()
                                    HStack {
                                        Text("Password protection")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    Text("When enabled, players must enter this password to join your quest. Share the password only with the people you want to participate.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding()
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                            }
                        }
                    }
                    .padding(.trailing, 12)
                    .toggleStyle(.switch)

                    if isPasswordProtected {
                        TextField("Enter a password", text: $password)
                            .textInputAutocapitalization(.never)
                            .textContentType(.password)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentingCreateChallenge) {
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
