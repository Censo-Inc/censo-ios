//
//  Intro.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI

extension EnterInfoForBeneficiary {
    struct Intro: View {
        @ObservedObject var router: Router
    
        var body: some View {
            VStack {
                Text("""
                 To ensure that your beneficiaries can access your seed phrases in case of unforeseen circumstances, you can provide additional information about your approvers and your seed phrases.
                 
                 The information about your approvers is visible to only you and your beneficiary, and only you may edit it.
                 
                 The information about your seed phrases is visible and editable only to you until your beneficiary successfully completes the takeover process, and then will be visible only to your beneficiary.
                 """)
                .font(.body)
                
                Spacer()
                
                Button {
                    router.navigate(to: .entryTypeChoice)
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.vertical)
            }
            .padding(.vertical)
            .padding(.horizontal, 32)
            .navigationInlineTitle("Legacy - Information")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { CloseButton() }
            }
        }
    }
}

