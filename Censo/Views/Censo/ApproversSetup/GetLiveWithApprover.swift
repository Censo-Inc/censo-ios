//
//  GetLiveWithApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct GetLiveWithApprover : View {
    @Environment(\.dismiss) var dismiss
    var approverName: String
    var showResumeLater = true
    var onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 16.0)
                        .fill(Color.gray)
                        .frame(maxWidth: 322, minHeight: 322, maxHeight: 322)
                        .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Get live with \(approverName)")
                        .font(.system(size: 24))
                        .bold()
                    
                    Text("For maximum security, it's best to be face-to-face with the person you're adding as an approver in a private location.")
                        .font(.system(size: 14))
                    
                    Text("This ensures direct and private sharing of the necessary codes and information, reducing the risk of eavesdropping and interception.")
                        .font(.system(size: 14))
                    
                    Button {
                        onContinue()
                    } label: {
                        Text("Continue live")
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    
                    if showResumeLater {
                        Button {
                            dismiss()
                        } label: {
                            Text("Resume later")
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                    }
                }
            }
            .padding([.top], 24)
            .padding([.leading, .trailing], 32)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ApproversSetup(
            session: Session.sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                guardianSetup: API.PolicySetup(
                    guardians: [
                        API.ProspectGuardian(
                            invitationId: try! InvitationId(value: ""),
                            label: "Me",
                            participantId: .random(),
                            status: API.GuardianStatus.initial(.init(
                                deviceEncryptedTotpSecret: Base64EncodedString(data: Data())
                            ))
                        ),
                        API.ProspectGuardian(
                            invitationId: try! InvitationId(value: ""),
                            label: "Neo",
                            participantId: .random(),
                            status: API.GuardianStatus.initial(.init(
                                deviceEncryptedTotpSecret: Base64EncodedString(data: Data())
                            ))
                        )
                    ],
                    threshold: 2
                )
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
