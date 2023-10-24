//
//  InitialApproversSetup.swift
//  Vault
//
//  Created by Brendan Flood on 10/16/23.
//

import SwiftUI

struct InitialApproversSetup: View {
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    @State private var showApproversSetup = false
    
    var body: some View {
        if showApproversSetup {
            ApproversSetup(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        } else {
            VStack(alignment: .leading, spacing: 30) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Optional: Increase security")
                        .font(.system(size: 18))
                        .bold()
                    Text("Invite trusted approvers")
                        .font(.system(size: 24))
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Invite up to two trusted approvers for an additional layer of security")
                        .font(.system(size: 14))
                    
                    Text("You can use either your primary or your backup approver along with your face scan to access your seed phrases. They help you keep the key but can never unlock the door.")
                        .font(.system(size: 14))
                }
                
                Button {
                    showApproversSetup = true
                } label: {
                    HStack {
                        Spacer()
                        Image("TwoPeopleWhite")
                            .resizable()
                            .frame(width: 32, height: 32)
                        Text("Invite approver(s)")
                            .font(.system(size: 24))
                        Spacer()
                    }
                }
                .buttonStyle(RoundedButtonStyle())
                
                Button {
                    dismiss()
                } label: {
                    Text("Skip this step")
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .frame(maxWidth: .infinity)
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
}

#if DEBUG
#Preview {
    NavigationView {
        InitialApproversSetup(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                unlockedForSeconds: UnlockedDuration(value: 600)
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
