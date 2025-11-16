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
    @EnvironmentObject private var auth: QHAuth
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
        .navigationDestination(isPresented: $navigate) {
            if let quest = foundQuest {
                PlayQuestView(quest: quest)
            } else {
                // Fallback in case state becomes inconsistent
                EmptyView()
            }
        }
    }
}

private extension SearchQuestView {
    func performSearch(with code: String) {
        isLoading = true
        QuestService.shared.searchQuest(
            byCode: code
        ) { result in
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

    func searchQuest() {
        guard !questCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        errorMessage = nil
        foundQuest = nil
        navigate = false
        
        let code = questCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    isLoading = false
                    errorMessage = AlertMessage(text: error.localizedDescription)
                    return
                }
                performSearch(with: code)
            }
        } else {
            performSearch(with: code)
        }
    }
}

#Preview {
    SearchQuestView()
}
