//
//  InitialApproversSetup.swift
//  Censo
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
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Optional: Additional security")
                        .font(.title3)
                        .bold()
                    Text("Invite trusted approvers")
                        .font(.title2)
                        .bold()
                }
                .padding(.horizontal)
                
                Text("""
                    Increase your security by adding trusted approvers. Access to your seed phrase will require their approval.

                    Adding a first approver ensures that your seed phrase is split into two fragments and encrypted for more security.

                    Adding a second approver ensures access to your seed phrase even if your first approver is unavailable. It also ensures that you can access your seed phrase in the event you lose your own login ID or your biometry fails.
                    """
                )
                .font(.subheadline)
                .padding(.horizontal)
                
                Button {
                    showApproversSetup = true
                } label: {
                    HStack {
                        Spacer()
                        Image("TwoPeopleWhite")
                            .resizable()
                            .frame(width: 32, height: 32)
                        Text("Invite approvers")
                            .font(.title2)
                        Spacer()
                    }
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                
                Button {
                    dismiss()
                } label: {
                    Text("No, I'm happy with none")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
            }
            .padding()
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
