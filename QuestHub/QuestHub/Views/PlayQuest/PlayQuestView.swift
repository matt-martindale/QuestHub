//
//  PlayQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/13/25.
//

import SwiftUI

struct PlayQuestView: View {
    @StateObject private var viewModel: PlayQuestViewModel
    
    init(auth: QHAuth, quest: Quest) {
        _viewModel = StateObject(wrappedValue: PlayQuestViewModel(auth: auth, quest: quest))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top)

                metadataCard
                    .padding(.horizontal)
                    .padding(.top, 16)

                descriptionCard
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                actions
                    .padding(.horizontal)
                    .padding(.top, 16)

                challengesSection
                    .padding(.horizontal)
                    .padding(.vertical, 20)
            }
        }
        .navigationTitle("Play Quest")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .alert(item: $viewModel.alertMessage) { msg in
            Alert(title: Text("Unable to join Quest"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $viewModel.showingPasswordSheet) {
            VStack(spacing: 16) {
                Text("This quest requires a password")
                    .font(.headline)
                
                
                    HStack(spacing: 8) {
                        Text(viewModel.passwordError ?? "")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                TextField("Password", text: $viewModel.inputPassword)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 30) {
                    Button("Cancel") {
                        viewModel.showingPasswordSheet = false
                        viewModel.inputPassword = ""
                        viewModel.passwordError = nil
                    }
                    Button("Confirm") {
                        viewModel.confirmPasswordAndJoin()
                        viewModel.inputPassword = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.inputPassword.isEmpty)
                }
            }
            .padding()
            .presentationDetents([.fraction(0.35), .medium])
        }
    }

    // MARK: - Subviews
    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            headerBackground
            headerTitles
                .padding(20)
        }
    }

    private var headerBackground: some View {
        ZStack {
            if viewModel.headerImageURL == nil {
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.35), .purple.opacity(0.35)], startPoint: .top, endPoint: .bottom))
                    Image(systemName: "map")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16/9, contentMode: .fit)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                AsyncImage(url: viewModel.headerImageURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.clear
                            ProgressView()
                                .tint(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        ZStack {
                            Rectangle()
                                .fill(LinearGradient(colors: [.blue.opacity(0.35), .purple.opacity(0.35)], startPoint: .top, endPoint: .bottom))
                            Image(systemName: "map")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(40)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
//        .frame(height: 240) // Hard cap the header height
//        .contentShape(Rectangle())
//        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//        .clipped() // Ensure anything inside doesn't overflow after shape clipping
//        .glassEffect(in: .rect(cornerRadius: 24))
    }

    private var headerTitles: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.quest.title ?? "")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
                .shadow(radius: 6)
            if let subtitle = viewModel.quest.subtitle {
                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 4)
            }
        }
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row: code + password badge + status chip aligned right
            HStack(alignment: .center, spacing: 8) {
                if let questCode = viewModel.quest.questCode, !questCode.isEmpty {
                    Text(questCode)
                        .font(.title3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }

                Spacer(minLength: 12)
                
                if let password = viewModel.quest.password, !password.isEmpty,
                   !viewModel.isJoined {
                    HStack(spacing: 6) {
                        Text("Password")
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .glassEffect(in: .capsule)
                }
                
                if viewModel.isJoined {
                    Text("Joined")
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .glassEffect(in: .capsule)
                }

                // Status chip
                questStatus
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .glassEffect(in: .capsule)
            }
            .padding(.vertical, -6)

            Divider().opacity(0.75)

            // Middle rows: creator + players on left, created/updated on right
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    if let creator = viewModel.quest.creatorDisplayName, !creator.isEmpty {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(creator)
                                    .font(.headline)
                                if let created = viewModel.quest.createdAt {
                                    Text(created.formatted(date: .abbreviated, time: .omitted))
                                        .font(.footnote)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    HStack {
                        if let maxPlayers = viewModel.quest.maxPlayers {
                            let current = viewModel.quest.playersCount ?? 0
                            metadataRow(icon: "person.2.fill", value: "\(current)/\(maxPlayers) players")
                                .padding(.leading, 8)
                        }
                        if let updated = viewModel.quest.updatedAt {
                            HStack(spacing: 6) {
                                Text("Last updated")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text(compactRelativeTime(from: updated))
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

//                Spacer(minLength: 12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var questStatus: some View {
        switch viewModel.quest.status {
        case .some(.paused):
            HStack(spacing: 8) {
                Text("Paused")
                    .font(.subheadline)
                Image(systemName: "pause.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
            }
        case .some(.active):
            HStack(spacing: 8) {
                Text("Active")
                    .font(.subheadline)
                Image(systemName: "bolt.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        case .some(.closed):
            HStack(spacing: 8) {
                Text("Closed")
                    .font(.subheadline)
                Image(systemName: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.qhPrimaryRed)
            }
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private func metadataRow(label: String? = nil, icon: String? = nil, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            if let label, !label.isEmpty {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
//                    .frame(width: 120, alignment: .leading)
            } else if let icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
                
            Text(value)
                .font(.footnote)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(0)
    }
    
    private func compactRelativeTime(from date: Date, reference: Date = Date()) -> String {
        let seconds = max(0, Int(reference.timeIntervalSince(date)))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour

        if seconds < hour {
            let m = max(1, seconds / minute)
            return "\(m)m ago"
        } else if seconds < day {
            let h = max(1, seconds / hour)
            return "\(h)h ago"
        } else {
            let d = max(1, seconds / day)
            return "\(d)d ago"
        }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About this quest")
                .font(.title3).bold()
            Text(viewModel.questDescription)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private var actions: some View {
        HStack(spacing: 12) {
            if !viewModel.isJoined {
                Button {
                    viewModel.beginJoinFlow()
                } label: {
                    Label("Join Quest", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }

            Button {
                // Share action
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
    }

    private var challengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenges")
                .font(.title3).bold()
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { idx in
                    challengeRow(index: idx)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private func challengeRow(index idx: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text("Challenge #\(idx + 1)")
                    .font(.headline)
                Text("A brief description of what to do for this challenge.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 14))
    }
}

#Preview {
    let auth = QHAuth()
    PlayQuestView(auth: auth, quest: Quest(id: "ID", questCode: "ABC", imageURL: "gs://questhubapp2025-db58e.firebasestorage.app/quests/3k4sTKiFi7XK37npGBxPb2FhoKA2/75845EC7-2828-42AA-BC87-50EE561D488C.jpg", title: "Title", subtitle: "Embark on an adventure", description: nil, maxPlayers: 20, playersCount: 5, challenges: nil, createdAt: Date(), updatedAt: Date(), creatorID: "creatorID", creatorDisplayName: "creatorDisplayName", status: .active, password: "Password", requireSignIn: true))
}

