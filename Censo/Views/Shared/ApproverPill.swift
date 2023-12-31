//
//  Approver.swift
//  Censo
//
//  Created by Ben Holzman on 10/26/23.
//

import SwiftUI

enum Approver {
    case prospect(API.ProspectApprover)
    case trusted(API.TrustedApprover)

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
    var onVerificationSubmitted: ((API.ApproverStatus.VerificationSubmitted) -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            if let isSelected {
                if isSelected {
                    Image(systemName: "checkmark")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .frame(width: 12, height: 12)
                        .padding([.trailing], 24)
                } else {
                    Text("")
                        .padding(.trailing, 36)
                }
            }

            VStack(alignment: .leading) {
                Text("Approver")
                    .font(.system(size: 14))
                    .bold()
                
                Text(approver.label())
                    .font(.system(size: 24))
                    .bold()
                
                switch approver {
                case .prospect(let approver):
                    switch approver.status {
                    case .declined:
                        Text("Declined")
                            .foregroundColor(.red)
                    case .initial:
                        Text("Not yet verified")
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
                        Text("Verified")
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
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(isSelected == true ? Color.Censo.primaryForeground : Color.gray, lineWidth: 1)
        )
    }
}
    
#if DEBUG
#Preview("without selection") {
    VStack {
        let trustedApprover = API.TrustedApprover(label: "Neo", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedApprover.Attributes(onboardedAt: Date()))
        ApproverPill(isPrimary: true, approver: .trusted(trustedApprover))
        ApproverPill(isPrimary: false, approver: .trusted(trustedApprover))
    }
    .foregroundColor(Color.Censo.primaryForeground)
}

struct ApproverPillsWithSelection_Previews: PreviewProvider {
    struct ContainerView: View {
        let approvers = [
            API.TrustedApprover(label: "Neo", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedApprover.Attributes(onboardedAt: Date())),
            API.TrustedApprover(label: "John Wick", participantId: ParticipantId(bigInt: generateParticipantId()), isOwner: false, attributes: API.TrustedApprover.Attributes(onboardedAt: Date())),
        ]
        @State var selectedApprover: API.TrustedApprover? = nil
            
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
        ContainerView().foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
    
