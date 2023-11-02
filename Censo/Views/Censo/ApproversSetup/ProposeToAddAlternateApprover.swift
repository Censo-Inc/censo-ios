//
//  ProposeToAddAlternateApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct ProposeToAddAlternateApprover : View {
    @Environment(\.dismiss) var dismiss
    
    var onAccept: () -> Void
    var onSkip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            Text("Invite a second approver?")
                .font(.system(size: 24))
                .bold()
            
            Text("""
                 Adding a second approver ensures access to your seed phrase even if your first approver is unavailable. It also ensures that you can access your seed phrase in the event you lose your own login ID or your biometry fails.

                 Your activated first approver ensures your seed phrase is split into two fragments and encrypted for more security, but adding a second approver is even more secure.
                 """)
                .font(.system(size: 14))
            
            Button {
                onAccept()
            } label: {
                Text("Invite a second")
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Button {
                onSkip()
            } label: {
                Text("No, I'm happy with one")
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
        }
        .padding([.leading, .trailing], 32)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        })
    }
}

#if DEBUG
#Preview {
    ProposeToAddAlternateApprover(
        onAccept: {},
        onSkip: {}
    )
}
#endif
