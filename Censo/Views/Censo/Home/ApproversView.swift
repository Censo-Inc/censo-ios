//
//  ApproversView.swift
//  Censo
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct ApproversView: View {
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showApproversSetup = false
    
    var body: some View {
        NavigationView {
            VStack {
                if ownerState.policy.externalApproversCount == 0 {
                    VStack(alignment: .leading, spacing: 30) {
                        Spacer()
                        
                        Text("Invite trusted approvers")
                            .font(.system(size: 24))
                            .bold()
                        
                        Text("""
                            Increase your security by adding trusted approvers. Access to your seed phrase will require their approval.

                            Adding a first approver ensures that your seed phrase is split into two fragments and encrypted for more security.

                            Adding a second approver ensures access to your seed phrase even if your first approver is unavailable. It also ensures that you can access your seed phrase in the event you lose your own login ID or your biometry fails.
                            """
                        )
                        .font(.system(size: 14))

                        Button {
                            showApproversSetup = true
                        } label: {
                            HStack {
                                Spacer()
                                Image("TwoPeopleWhite")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Text(ownerState.policySetup == nil ? "Invite approvers" : "Resume approvers setup")
                                Spacer()
                            }
                        }
                        .buttonStyle(RoundedButtonStyle())
                        
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Learn more")
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .padding([.leading, .trailing], 52)
                } else {
                    VStack(spacing: 30) {
                        let approvers = ownerState.policy.guardians
                            .filter({ !$0.isOwner })
                            .sorted(using: KeyPathComparator(\.attributes.onboardedAt))

                        ForEach(Array(approvers.enumerated()), id: \.offset) { i, approver in
                          ApproverPill(isPrimary: i == 0, approver: .trusted(approver))
                        }
                        Spacer()
                    }
                    .padding([.top], 30)
                    .padding([.leading, .trailing], 30)
                }
                
                Divider()
                    .padding([.bottom], 4)
            }
            .navigationTitle(Text("Approvers"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showApproversSetup, content: {
                NavigationView {
                    ApproversSetup(
                        session: session,
                        ownerState: ownerState,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                }
            })
        }
    }
}

#if DEBUG
#Preview("No approvers") {
    ApproversView(
        session: .sample,
        ownerState: API.OwnerState.Ready(
            policy: .sample,
            vault: .sample,
            recovery: nil
        ),
        onOwnerStateUpdated: { _ in }
    )
}

#Preview("2 approvers") {
    ApproversView(
        session: .sample,
        ownerState: API.OwnerState.Ready(
            policy: .init(
                createdAt: Date(),
                guardians: [.sampleOwner, .sample2, .sample3],
                threshold: 2,
                encryptedMasterKey: Base64EncodedString(data: Data()),
                intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
            ),
            vault: .sample,
            recovery: nil
        ),
        onOwnerStateUpdated: { _ in }
    )
}
#endif
