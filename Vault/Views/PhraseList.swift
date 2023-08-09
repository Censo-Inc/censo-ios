//
//  PhraseList.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct PhraseList: View {
    @StateObject private var vaultStorage: VaultStorage

    @State private var showingAddPhrase = false
    @State private var selection: DecodedPhrase?
    @State private var error: Error? = nil
    @State private var showingAlert = false

    init(vaultStorage: @autoclosure @escaping () -> VaultStorage) {
        self._vaultStorage = StateObject(wrappedValue: vaultStorage())
    }

    var body: some View {
        NavigationStack {
            List {
                let names = vaultStorage.names

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
                        showingAddPhrase = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addPhrase")
                }
            }
            .sheet(isPresented: $showingAddPhrase) {
                NewPhrase(vaultStorage: vaultStorage)
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
        vaultStorage.decodedPhrase(name: name) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let decodedPhrase):
                    self.selection = decodedPhrase
                case .failure(let error):
                    self.error = error
                    self.showingAlert = true
                }
            }
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
        PhraseList(vaultStorage: VaultStorage(vault: .sample, deviceKey: .sample))
    }
}

extension Vault {
    static var sample: Self {
        Vault(entries: ["Sample": Phrase(createdAt: Date(), encryptedWords: Data())])
    }
}
#endif
