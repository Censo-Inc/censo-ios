//
//  ApproverRouting.swift
//  Approver
//
//  Created by Brendan Flood on 10/4/23.
//

import SwiftUI

struct ApproverRouting: View {
    @Binding var inviteCode: String
    @Binding var participantId: ParticipantId
    @Binding var route: ApproverRoute
    var session: Session
    var onSuccess: () -> Void
    
    var body: some View {
        switch (route) {
        case .onboard:
            Onboarding(
                inviteCode: inviteCode,
                session: session,
                onSuccess: onSuccess
            )
        case .access:
            AccessApproval(
                session: session,
                participantId: participantId,
                onSuccess: onSuccess
            )
        case .initial:
            ProgressView()
        }
    }
}

