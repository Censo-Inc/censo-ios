//
//  Approver.swift
//  Censo
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
    var isSelected: Bool?
    var onEdit: (() -> Void)?
    var onVerificationSubmitted: ((API.GuardianStatus.VerificationSubmitted) -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            if let isSelected {
                if isSelected {
                    Image(systemName: "checkmark")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundColor(.black)
                        .frame(width: 12, height: 12)
                        .padding([.trailing], 24)
                } else {
                    Text("")
                        .padding(.trailing, 36)
                }
            }

            VStack(alignment: .leading) {
                Text("\(isPrimary ? "Primary": "Alternate") approver")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .bold()
                
                Text(approver.label())
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .bold()
                
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
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(isSelected == true ? Color.black : Color.gray, lineWidth: 1)
        )
    }
}
    
#if DEBUG
#Preview("without selection") {
    VStack {
        let trustedApprover = API.TrustedGuardian(label: "Neo", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date()))
        ApproverPill(isPrimary: true, approver: .trusted(trustedApprover))
        ApproverPill(isPrimary: false, approver: .trusted(trustedApprover))
    }
}

struct ApproverPillsWithSelection_Previews: PreviewProvider {
    struct ContainerView: View {
        let approvers = [
            API.TrustedGuardian(label: "Neo", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date())),
            API.TrustedGuardian(label: "John Wick", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedGuardian.Attributes(onboardedAt: Date())),
        ]
        @State var selectedApprover: API.TrustedGuardian? = nil
            
        var body: some View {
            VStack {
                ForEach(Array(approvers.enumerated()), id: \.offset) { i, approver in
                    ApproverPill(isPrimary: i == 0, approver: .trusted(approver), isSelected: approver.participantId == selectedApprover?.participantId)
                        .onTapGesture {
                            selectedApprover = approver
                        }
                }
            }
        }
    }
    
    static var previews: some View {
        ContainerView()
    }
}
#endif
    
