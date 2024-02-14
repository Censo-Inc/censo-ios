//
//  EntryTypeChoice.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI

extension EnterInfoForBeneficiary {
    struct EntryTypeChoice: View {
        @ObservedObject var router: Router
        
        var body: some View {
            VStack {
                Spacer()
                
                Text("Your beneficiary will need the assistance of your approvers to takeover your account. Provide any necessary contact information for your approvers.")
                    .font(.body)
                
                Button {
                    router.navigate(to: .approversContactInfoEntry)
                } label: {
                    Text("Approver information")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.vertical)
                
                Spacer()
                    .frame(maxHeight: 50)
                
                Text("You can also provide additional information about your seed phrases to ensure your beneficiary will be able to access your assets.")
                    .font(.body)
                
                Button {
                    router.navigate(to: .seedPhrasesList)
                } label: {
                    Text("Seed phrase information")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.vertical)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.horizontal, 32)
            .navigationInlineTitle("Legacy - Information")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            }
        }
    }
}
