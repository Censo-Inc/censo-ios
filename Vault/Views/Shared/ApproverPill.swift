//
//  Approver.swift
//  Vault
//
//  Created by Ben Holzman on 10/26/23.
//

import SwiftUI

enum Approver {
    case prospect(API.ProspectGuardian)
    case trusted(API.TrustedGuardian)

    func label() -> String {
        switch (self) {
        case .prospect(let approver):
            return approver.label
        case .trusted(let approver):
            return approver.label
        }
    }
}

struct ApproverPill: View {
    var isPrimary: Bool
    var approver: Approver
    var onEdit: (() -> Void)?
    var onVerificationSubmitted: ((API.GuardianStatus.VerificationSubmitted) -> Void)?
    
    var body: some View {
        VStack(spacing: 30) {
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(isPrimary ? "Primary": "Alternate") approver")
                        .font(.system(size: 14))
                        .bold()
                    
                    HStack {
                        Text(approver.label())
                            .font(.system(size: 24))
                            .bold()
                        
                        Spacer()

                        if (onEdit != nil) {
                            Button {
                                onEdit?()
                            } label: {
                                Image("Pencil")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    switch approver {
                    case .prospect(let approver):
                        switch approver.status {
                        case .declined:
                            Text("Declined")
                                .foregroundColor(.red)
                        case .initial:
                            Text("Not yet active")
                                .foregroundColor(.Censo.gray)
                        case .accepted:
                            Text("Opened link in app")
                                .foregroundColor(.Censo.gray)
                        case .verificationSubmitted(let verificationSubmitted):
                            Text("Checking Code")
                                .foregroundColor(.Censo.gray)
                                .onAppear {
                                    onVerificationSubmitted?(verificationSubmitted)
                                }
                        case .confirmed:
                            Text("Active")
                                .foregroundColor(.Censo.green)
                        case .implicitlyOwner:
                            Text("")
                        }
                    case .trusted:
                        Text("Active")
                            .foregroundColor(.Censo.green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16.0)
                    .stroke(Color.gray, lineWidth: 1)
            )    }
    }
}
    
#if DEBUG
#Preview {
    ApproverPill(isPrimary: true, approver: .trusted(API.TrustedGuardian(label: "Neo", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date()))))
}
#endif
    
