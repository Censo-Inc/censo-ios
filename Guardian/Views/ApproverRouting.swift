//
//  ApproverRouting.swift
//  Guardian
//
//  Created by Brendan Flood on 10/4/23.
//

import SwiftUI

struct ApproverRouting: View {
    @Binding var inviteCode: String
    @Binding var participantId: ParticipantId
    @Binding var route: GuardianRoute
    var session: Session
    var onSuccess: () -> Void
    
    var body: some View {
        switch (route) {
        case .recovery:
            RecoveryApproval(
                session: session,
                participantId: participantId,
                onSuccess: onSuccess
            )
        case .onboard:
            Onboarding(
                inviteCode: inviteCode,
                session: session,
                onSuccess: onSuccess
            )
        case .initial:
            ProgressView()
        case .unknown:
            Text("Unknown URL")
        }
    }
}

