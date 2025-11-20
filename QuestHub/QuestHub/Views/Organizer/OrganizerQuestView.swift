//
//  OrganizerQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/19/25.
//

import SwiftUI

struct OrganizerQuestView: View {
    @EnvironmentObject private var auth: QHAuth
    @StateObject private var viewModel: OrganizerQuestViewModel
    @State private var showSignIn = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showStatusPicker = false
    @State private var selectedStatus: QuestStatus = .active
    
    init(quest: Quest) {
        _viewModel = StateObject(wrappedValue: OrganizerQuestViewModel(quest: quest))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top)
                
                metadataCard
                    .padding(.horizontal)
                    .padding(.top)
                
//                updateQuestStatus
//                    .padding(.horizontal)
//                    .padding(.top)
            }
        }
        .navigationTitle("Quest Details")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showStatusPicker) {
            StatusPickerSheet(
                current: viewModel.quest.status ?? .active,
                selection: $selectedStatus,
                onCancel: { showStatusPicker = false },
                onConfirm: {
                    viewModel.status = selectedStatus
                    viewModel.quest.status = selectedStatus
                    viewModel.updateQuestStatus()
                    showStatusPicker = false
                    showToast(with: "Status updated!")
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var header: some View {
        ZStack(alignment: .bottomLeading) {
//            headerBackground
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
    }

    private var headerTitles: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.quest.title ?? "")
                .font(.largeTitle).bold()
                .foregroundStyle(.primary)
                .shadow(radius: 6)
            if let subtitle = viewModel.quest.subtitle {
                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(.primary.opacity(0.9))
                    .shadow(radius: 4)
            }
        }
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                if let questCode = viewModel.quest.questCode, !questCode.isEmpty {
                    HStack(spacing: 6) {

                        Button {
                            UIPasteboard.general.string = questCode
                            showToast(with: "\(questCode) copied!")
                        } label: {
                            HStack {
                                Text(questCode)
                                    .font(.title3)
                                
                                Image(systemName: "hand.rays.fill")
                                    .font(.footnote)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .glassEffect(in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy quest code")
                    }
                }

                Spacer(minLength: 12)
                
                if let password = viewModel.quest.password, !password.isEmpty {
                    HStack(spacing: 6) {
                        Text(password)
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
            }
            .padding(.vertical, -6)

            Divider().opacity(0.75)
            
            VStack {
                HStack(spacing: 12) {
                    // Status chip
                    questStatus
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .glassEffect(in: .capsule)
                    
                    Text(viewModel.statusDetails)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                updateQuestStatus
                    .padding(.top)
            }
            
            Divider().opacity(0.75)
            
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
    
    private var updateQuestStatus: some View {
        HStack(spacing: 12) {
            Button {
                selectedStatus = viewModel.quest.status ?? .active
                showStatusPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.sparkles")
                    Text("Update Quest status")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .tint(Color.qhPrimaryBlue)
            .buttonStyle(.glass)
        }
    }
    
    private func showToast(with message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showToast = false
            }
        }
    }
    
}

private struct StatusPickerSheet: View {
    let current: QuestStatus
    @Binding var selection: QuestStatus
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            Text("Update Quest Status")
                .font(.headline)

            Picker("Status", selection: $selection) {
                ForEach(QuestStatus.allCases, id: \.self) { status in
                    let color: Color = {
                        switch selection {
                        case .active: return .green
                        case .paused: return .yellow
                        case .closed: return Color.qhPrimaryRed
                        }
                    }()
                    return Text(status.displayTitle)
                        .fontWeight(status == current ? .semibold : .regular)
                        .foregroundStyle(status == selection ? color : .primary)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Update") { onConfirm() }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

private extension QuestStatus {
    var displayTitle: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .closed: return "Closed"
        }
    }
}

#Preview {
    let auth = QHAuth()
    OrganizerQuestView(quest: Quest(id: "ID", questCode: "ABC", imageURL: "gs://questhubapp2025-db58e.firebasestorage.app/quests/3k4sTKiFi7XK37npGBxPb2FhoKA2/75845EC7-2828-42AA-BC87-50EE561D488C.jpg", title: "Title", subtitle: "Embark on an adventure", description: nil, maxPlayers: 20, playersCount: 5, challenges: nil, createdAt: Date(), updatedAt: Date(), creatorID: "creatorID", creatorDisplayName: "creatorDisplayName", status: .active, password: "Password123", requireSignIn: true))
        .environmentObject(auth)
}
