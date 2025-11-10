//
//  SearchQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SearchQuestView: View {
    @State private var questCode: String = ""
    @State private var isLoading: Bool = false
    private struct AlertMessage: Identifiable { let id = UUID(); let text: String }
    @State private var errorMessage: AlertMessage?
    @State private var foundQuest: Quest?
    @State private var navigate: Bool = false

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
                searchQuest()
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
        .alert(item: $errorMessage) { msg in
            Alert(title: Text("Error"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .background(
            NavigationLink(destination: QuestDetailPlaceholderView(quest: foundQuest), isActive: $navigate) {
                EmptyView()
            }
            .hidden()
        )
    }
}

private extension SearchQuestView {
    func searchQuest() {
        guard !questCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        foundQuest = nil
        navigate = false

        let code = questCode.trimmingCharacters(in: .whitespacesAndNewlines)
        QuestService.shared.searchAndJoin(questCode: code,
                                          userId: Auth.auth().currentUser?.uid ?? "",
                                          userDisplayName: Auth.auth().currentUser?.displayName ?? "Player") { result in
            isLoading = false
            switch result {
            case .success(let quest):
                foundQuest = quest
                navigate = true
            case .failure(let error):
                errorMessage = AlertMessage(text: error.localizedDescription)
            }
        }
    }
}

struct QuestDetailPlaceholderView: View {
    let quest: Quest?
    var body: some View {
        VStack(spacing: 12) {
            Text(quest?.title ?? "Quest")
                .font(.title)
            Text("Code: \(quest?.id ?? "-")")
                .foregroundStyle(.secondary)
            Text("Players: \(String(quest?.playersCount ?? 0))/\(String(quest?.maxPlayers ?? 0))")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Quest")
    }
}

#Preview {
    SearchQuestView()
}
