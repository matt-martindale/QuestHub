//
//  SearchQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct SearchQuestView: View {
    @State private var questCode: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(UIStrings.enterQuestCode)
                .font(.largeTitle).bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(UIStrings.exampleQuestCode, text: $questCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .textFieldStyle(.roundedBorder)

            Button(action: {
                // TODO: Trigger search for quest using questCode
            }) {
                Text(UIStrings.search)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(questCode.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                    .foregroundColor(questCode.isEmpty ? .secondary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(questCode.isEmpty)

            Spacer()
            Spacer()
        }
        .padding()
        .navigationTitle(UIStrings.searchQuest)
    }
}

#Preview {
    SearchQuestView()
}
