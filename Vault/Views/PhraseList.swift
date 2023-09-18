//
//  PhraseList.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct PhraseList: View {
    @State private var selection: DecodedPhrase?
    @State private var error: Error? = nil
    @State private var showingAlert = false
    @State private var currentSheet: Sheet?

    enum Sheet {
        case addPhrase
        case guardianSetup
    }

    var names: [String] { [] }

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<names.count, id: \.self) { i in
                    let name = names[i]

                    Button {
                        present(name: name)
                    } label: {
                        Text(name)
                    }
                    .accessibilityIdentifier(name)
                }
            }
            .navigationTitle(Text("Phrases"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        currentSheet = .addPhrase
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addPhrase")
                }
            }
            .sheet(item: $currentSheet) { sheet in
                switch sheet {
                case .addPhrase:
                    NewPhrase()
                case .guardianSetup:
                    OwnerSetup()
                }
            }
            .alert("Error", isPresented: $showingAlert, presenting: error) { _ in
                Button {

                } label: {
                    Text("OK")
                }
            } message: { error in
                Text("There was an issue retrieving the phrase from your vault.\n\(error.localizedDescription)")
            }

            NavigationLink(isActive: Binding(get: {
                selection != nil
            }, set: { _ in
                selection = nil
            })
            ) {
                if let selection = selection {
                    PhraseView(name: selection.name, createdAt: selection.createdAt, phrase: selection.words)
                }
            } label: {
                EmptyView()
            }
        }
    }

    private func present(name: String) {

    }
}

extension PhraseList.Sheet: Identifiable {
    var id: Int {
        switch self {
        case .addPhrase:
            return 0
        case .guardianSetup:
            return 1
        }
    }
}

extension DateFormatter {
    static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

#if DEBUG
struct PhraseList_Previews: PreviewProvider {
    static var previews: some View {
        PhraseList()
    }
}

extension Vault {
    static var sample: Self {
        Vault(entries: ["Sample": Phrase(createdAt: Date(), encryptedWords: Data())])
    }
}
#endif
