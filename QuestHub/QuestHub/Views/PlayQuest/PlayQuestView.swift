//
//  PlayQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/13/25.
//

import SwiftUI

struct PlayQuestView: View {
    @EnvironmentObject private var auth: QHAuth
    @StateObject private var viewModel: PlayQuestViewModel
    @State private var showSignIn = false
    @State private var showAccount = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    init(quest: Quest) {
        _viewModel = StateObject(wrappedValue: PlayQuestViewModel(quest: quest))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top)

                metadataCard
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                actions
                    .padding(.horizontal)
                    .padding(.top, 16)

                descriptionCard
                    .padding(.horizontal)
                    .padding(.top, 16)

                challengesSection
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                leaveQuest
                    .padding(.horizontal)
                    .padding(.vertical, 20)
            }
        }
        .refreshable {
            viewModel.refresh(userId: auth.currentUser?.id)
        }
        .navigationTitle("Play Quest")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .task(id: auth.currentUser?.id) {
            viewModel.onAppear(userId: auth.currentUser?.id)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if auth.currentUser != nil {
                    Menu {
                        Button("Account", systemImage: "person.fill") {
                            showAccount = true
                        }
                        Button(role: .destructive) {
                            auth.signOut()
                        } label: {
                            Label(UIStrings.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                } else {
                    Button("Sign in") {
                        showSignIn = true
                    }
                }
            }
        }
        .alert(item: $viewModel.alertMessage) { msg in
            Alert(title: Text("Unable to join Quest"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .alert("Leave this quest?", isPresented: $viewModel.showingLeaveConfirmation) {
            Button("Leave Quest", role: .destructive) {
                viewModel.leaveQuest(currentUser: auth.currentUser)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You’ll lose access to challenges and progress.")
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInView()
            }
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack {
                AccountView()
            }
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
                
                HStack {
                    Text("Not case-sensitive.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)

                TextField("Password", text: $viewModel.inputPassword)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                HStack() {
                    Button("Cancel") {
                        viewModel.showingPasswordSheet = false
                        viewModel.inputPassword = ""
                        viewModel.passwordError = nil
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("Confirm") {
                        viewModel.confirmPasswordAndJoin(currentUser: auth.currentUser)
                        viewModel.inputPassword = ""
                    }
                    .padding(.horizontal)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.inputPassword.isEmpty)
                }
            }
            .padding()
            .presentationDetents([.fraction(0.35), .medium])
        }
        .onChange(of: viewModel.isJoined) { oldValue, newValue in
            // Only show a toast when the state meaningfully changes
            if newValue == true && oldValue == false {
                showToast(with: "Joined quest!")
            } else if newValue == false && oldValue == true {
                showToast(with: "Left quest")
            }
        }
        .overlay(alignment: .bottom) {
            if showToast {
                Text(toastMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.85), in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showToast)
            }
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
                            Spacer()
                            Text("\(viewModel.points) pts")
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .glassEffect(in: .capsule)
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
                    viewModel.beginJoinFlow(currentUser: auth.currentUser)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Join Quest")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .tint(.green)
                .buttonStyle(.glass)
            }
            
            Button {
                // TODO: Implement share sheet for quest
                showToast(with: "Share coming soon")
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glass)
        }
    }

    private var challengesSection: some View {
        ZStack {
            // Existing Challenges card content
            VStack(alignment: .leading, spacing: 12) {
                Text("Challenges")
                    .font(.title3).bold()
                VStack(spacing: 12) {
                    if viewModel.isLoadingChallenges {
                        HStack {
                            ProgressView().padding(.trailing, 8)
                            Text("Loading challenges…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    } else if !viewModel.userChallenges.isEmpty {
                        ForEach(viewModel.userChallenges, id: \.id) { challenge in
                            ChallengeRowView(challenge: challenge)
                        }
                    } else if viewModel.isJoined {
                        Text("No challenges yet. Pull to refresh or try again later.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Join the quest to see and play challenges.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glassEffect(in: .rect(cornerRadius: 20))

            // Paused overlay
            if viewModel.quest.status == .paused {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .overlay(
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundStyle(.yellow)
                            Text("Quest is paused")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(12)
                        .background(
                            Capsule().fill(Color.black.opacity(0.35))
                        )
                        .foregroundStyle(.white)
                    )
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var leaveQuest: some View {
        HStack {
            if viewModel.isJoined {
                Button {
                    // Trigger confirmation before leaving
                    viewModel.showingLeaveConfirmation = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .symbolRenderingMode(.hierarchical)
                        Text("Leave Quest")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .tint(.red)
                .buttonStyle(.glass)
                .accessibilityLabel("Leave this quest")
                .accessibilityHint("Double tap to confirm and leave the quest")
            }
        }
    }
    
    private func showToast(with message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showToast = false
            }
        }
    }
}

#Preview {
    let auth = QHAuth()
    PlayQuestView(quest: Quest(id: "ID", questCode: "ABC", imageURL: "gs://questhubapp2025-db58e.firebasestorage.app/quests/3k4sTKiFi7XK37npGBxPb2FhoKA2/75845EC7-2828-42AA-BC87-50EE561D488C.jpg", title: "Title", subtitle: "Embark on an adventure", description: nil, maxPlayers: 20, playersCount: 5, challenges: nil, createdAt: Date(), updatedAt: Date(), creatorID: "creatorID", creatorDisplayName: "creatorDisplayName", status: .active, password: "Password", requireSignIn: true))
        .environmentObject(auth)
}

