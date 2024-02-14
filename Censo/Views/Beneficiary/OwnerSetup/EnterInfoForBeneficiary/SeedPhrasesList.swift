//
//  SeedPhrasesList.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI

extension EnterInfoForBeneficiary {
    struct SeedPhrasesList: View {
        @Environment(\.dismiss) var dismiss
        @EnvironmentObject var ownerRepository: OwnerRepository
        
        @ObservedObject var router: Router
        var policy: API.Policy
        var vault: API.Vault
        
        var body: some View {
            List {
                ForEach(0 ..< vault.seedPhrases.count, id: \.self) { i in
                    let phrase = vault.seedPhrases[i]
                    
                    Button {
                        router.navigate(to: .seedPhraseNotesEntry(phrase: phrase))
                    } label: {
                        HStack {
                            SeedPhrasePill(seedPhrase: phrase)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                if phrase.encryptedNotes == nil {
                                    Image(systemName: "plus")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    Image(systemName: "chevron.forward")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
                            .symbolRenderingMode(.palette)
                            .frame(width: 24, height: 24)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .padding(.vertical)
            .navigationInlineTitle("Legacy - Seed phrase information")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        @StateObject var router = EnterInfoForBeneficiary.Router(path: [])
    
        VStack {}
            .sheet(isPresented: Binding.constant(true)) {
                NavigationStack {
                    EnterInfoForBeneficiary.SeedPhrasesList(
                        router: router,
                        policy: .sample2ApproversAndAcceptedBeneficiary,
                        vault: API.Vault(
                            seedPhrases: [.sampleWithNotes, .sample2, .sample3, .sample4, .sample5],
                            publicMasterEncryptionKey: API.Vault.samplePublicMasterEncryptionKey
                        )
                    )
                }
            }
    }
}
#endif
