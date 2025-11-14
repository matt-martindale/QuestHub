//
//  PlayQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/13/25.
//

import SwiftUI

struct PlayQuestView: View {
    @StateObject private var viewModel: PlayQuestViewModel
    
    init(quest: Quest) {
        _viewModel = StateObject(wrappedValue: PlayQuestViewModel(quest: quest))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top)

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
            Button {
                // Start or continue quest action
            } label: {
                Label("Start Quest", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)

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
    PlayQuestView(quest: Quest(id: "ID", questCode: "ABC", imageURL: "gs://questhubapp2025-db58e.firebasestorage.app/quests/3k4sTKiFi7XK37npGBxPb2FhoKA2/75845EC7-2828-42AA-BC87-50EE561D488C.jpg", title: "Title", subtitle: "Embark on an adventure", description: nil, maxPlayers: 20, playersCount: 5, challenges: nil, createdAt: Date(), updatedAt: Date(), creatorID: "creatorID", creatorDisplayName: "creatorDisplayName", status: .active, password: "Password", requireSignIn: true))
}
