//
//  NewPhrase.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct NewPhrase: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var words: String = ""
    @State private var error: Error? = nil
    @State private var showingAlert = false

    var vaultStorage: VaultStorage

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                Text("Name:")
                TextField("", text: $name)
                    .accessibilityIdentifier("nameField")

                Text("BIP39 Phrase:")
                TextField("", text: $words)
                    .accessibilityIdentifier("wordsField")

                Spacer()

                Button {
                    do {
                        try vaultStorage.insertPhrase(withName: name, words: words)
                        dismiss()
                    } catch {
                        self.error = error
                        self.showingAlert = true
                    }
                } label: {
                    Text("Add to Vault")
                        .frame(maxWidth: .infinity)
                }
                .disabled(name.isEmpty || words.isEmpty)
                .accessibilityIdentifier("addToVaultButton")
            }
            .padding(30)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .buttonStyle(FilledButtonStyle())
            .navigationTitle(Text("New Phrase"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert, presenting: error) { _ in
                Button {

                } label: {
                    Text("OK")
                }
            } message: { error in
                Text("There was an issue adding the phrase your vault.\n\(error.localizedDescription)")
            }
        }
    }
}

#if DEBUG
struct NewPhrase_Previews: PreviewProvider {
    static var previews: some View {
        NewPhrase(vaultStorage: .init(vault: .sample, deviceKey: .sample))
    }
}
#endif
