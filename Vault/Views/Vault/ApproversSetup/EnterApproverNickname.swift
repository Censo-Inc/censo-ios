//
//  EnterApproverNickname.swift
//  Vault
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct EnterApproverNickname: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var nickname: String = ""
    var onSave: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            Text("Add approver nickname")
                .font(.system(size: 24))
                .bold()
            
            Text("Give your approver a nickname of your choice so you can identify them in the future.")
                .font(.system(size: 14))
            
            Text("This will be visible only to you.")
                .font(.system(size: 14))
            
            TextField(text: $nickname) {
                Text("Enter a nickname...")
            }
            .textFieldStyle(RoundedTextFieldStyle())
            .font(.system(size: 24))
            .frame(maxWidth: .infinity)
            
            Button {
                onSave(nickname)
            } label: {
                Text("Save")
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(nickname.isEmpty)
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
    NavigationView {
        ApproversSetup(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                guardianSetup: nil
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
