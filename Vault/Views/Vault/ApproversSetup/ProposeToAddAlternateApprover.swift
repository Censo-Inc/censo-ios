//
//  ProposeToAddAlternateApprover.swift
//  Vault
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
            
            Text("Add an alternate approver?")
                .font(.system(size: 24))
                .bold()
            
            Text("For added peace of mind, add an alternate approver. You can use either your primary or your alternate approver along with your face scan to access your seed phrase.")
                .font(.system(size: 14))
            
            Button {
                onAccept()
            } label: {
                Text("Invite alternate")
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Button {
                onSkip()
            } label: {
                Text("Save & finish")
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
