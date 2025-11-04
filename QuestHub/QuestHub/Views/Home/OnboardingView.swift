//
//  OnboardingView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page: Int = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                OnboardingPageView(
                    title: "Welcome to QuestHub",
                    subtitle: "Track quests, stay motivated, and level up your progress.",
                    systemImage: "sparkles"
                )
                .tag(0)

                OnboardingPageView(
                    title: "Organize",
                    subtitle: "Group your tasks and quests, set priorities, and focus on what matters.",
                    systemImage: "tray.full"
                )
                .tag(1)

                OnboardingPageView(
                    title: "Achieve",
                    subtitle: "Complete quests and celebrate your wins with insightful stats.",
                    systemImage: "chart.bar.xaxis"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            }) {
                Text(page < 2 ? "Next" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .background(
            LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}
