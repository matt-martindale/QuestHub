//
//  OnboardingPageView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 32)
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .frame(width: 120, height: 120)
            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
}

#Preview("Onboarding Page") {
    OnboardingPageView(
        title: "Track Quests",
        subtitle: "Create, manage, and complete quests to level up your productivity.",
        systemImage: "checkmark.seal.fill"
    )
}
