//
//  SavedAndSharded.swift
//  Vault
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct SavedAndSharded : View {
    var secrets: [API.VaultSecret]
    var approvers: [API.TrustedGuardian]
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            HStack {
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.black)
                    .frame(maxWidth: 162, maxHeight: 162)
                
                Spacer()
            }
            
            Text("Saved & sharded")
                .font(.system(size: 24))
                .bold()
                .padding([.leading, .trailing], 32)
                .padding([.top], 25)
                .padding([.bottom], 10)
            
            if secrets.count > 0 {
                Text(secrets.count == 1 ? secrets[0].label : "\(secrets.count) Seed Phrases")
                .font(.system(size: 24))
                .padding([.leading, .trailing], 32)
            }
            
            HStack {
                Spacer()
                
                Divider()
                    .frame(width: 1)
                    .overlay(.black)
                
                Spacer()
            }
            .frame(maxHeight: 44)
            .padding(.vertical, 10)
            
            let approverNames = approvers
                .filter({ !$0.isOwner })
                .sorted(using: KeyPathComparator(\.attributes.onboardedAt))
                .map({ $0.label })

            VStack {
                ForEach(approverNames, id: \.self) { approver in
                    Text(approver)
                        .font(.system(size: 24))
                        .padding([.vertical], 1)
                }
            }
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("1 phrase") {
    NavigationView {
        let now = Date.now
        
        SavedAndSharded(
            secrets: [
                API.VaultSecret(
                    guid: "",
                    encryptedSeedPhrase: .sample,
                    seedPhraseHash: .sample,
                    label: "Phrase 1",
                    createdAt: Date.now
                )
            ],
            approvers: [
                API.TrustedGuardian(
                    label: "John Wick",
                    participantId: .random(),
                    isOwner: false,
                    attributes: API.TrustedGuardian.Attributes(
                        onboardedAt: Calendar.current.date(byAdding: .minute, value: -1, to: now)!                    
                    )
                ),
                API.TrustedGuardian(
                    label: "Me",
                    participantId: .random(),
                    isOwner: true,
                    attributes: API.TrustedGuardian.Attributes(
                        onboardedAt: Calendar.current.date(byAdding: .minute, value: -1, to: now)!                    
                    )
                ),
                API.TrustedGuardian(
                    label: "Neo",
                    participantId: .random(),
                    isOwner: false,
                    attributes: API.TrustedGuardian.Attributes(
                        onboardedAt: Calendar.current.date(byAdding: .minute, value: -2, to: now)!
                    )
                )
            ]
        )
    }
}

#Preview("Multiple phrases") {
    NavigationView {
        SavedAndSharded(
            secrets: [
                API.VaultSecret(
                    guid: "",
                    encryptedSeedPhrase: .sample,
                    seedPhraseHash: .sample,
                    label: "Phrase 1",
                    createdAt: Date.now
                ),
                API.VaultSecret(
                    guid: "",
                    encryptedSeedPhrase: .sample,
                    seedPhraseHash: .sample,
                    label: "Phrase 2",
                    createdAt: Date.now
                )
            ],
            approvers: [
                API.TrustedGuardian(label: "Neo", participantId: .random(), isOwner: false, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date.now)),
                API.TrustedGuardian(label: "Me", participantId: .random(), isOwner: true, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date.now)),
                API.TrustedGuardian(label: "John Wick", participantId: .random(), isOwner: false, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date.now))
            ]
        )
    }
}
#endif
