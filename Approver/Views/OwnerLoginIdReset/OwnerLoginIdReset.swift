//
//  OwnerLoginIdReset.swift
//  Approver
//
//  Created by Anton Onyshchenko on 03.01.24.
//

import Foundation
import SwiftUI
import Moya

struct OwnerLoginIdReset: View {
    @Environment(\.dismiss) var dismiss
    
    private var session: Session
    @Binding private var user: API.ApproverUser
    @State private var step: Step
    
    enum Step {
        case chooseOwner
        case getLiveWithOwner(Owner)
        case createResetToken(Owner)
        case shareResetLink(URL)
    }
    
    init(session: Session, user: Binding<API.ApproverUser>) {
        self.session = session
        self._user = user
        self._step = State(
            initialValue: user.approverStates.count == 1 ? .getLiveWithOwner(user.wrappedValue.approverStates[0].toOwner()) : .chooseOwner
        )
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch (step) {
                case .chooseOwner:
                    ChooseOwner(
                        owners: user.approverStates.map({ $0.toOwner() }),
                        onContinue: {
                            self.step = .getLiveWithOwner($0)
                        }
                    )
                case .getLiveWithOwner(let owner):
                    GetLiveWithOwner(
                        intent: .loginIdReset,
                        onContinue: {
                            self.step = .createResetToken(owner)
                        },
                        onBack: user.approverStates.count > 1 ? {
                            self.step = .chooseOwner
                        } : nil
                    )
                case .createResetToken(let owner):
                    CreateOwnerLoginIdResetToken(
                        session: session,
                        participantId: owner.participantId,
                        user: $user,
                        onSuccess: { token in
                            self.step = .shareResetLink(token.url)
                        }
                    )
                case .shareResetLink(let link):
                    ShareOwnerLoginIdResetLink(link: link)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Login assistance"))
            .navigationBarBackButtonHidden(true)
        }
    }
}

#if DEBUG
#Preview {
    @State var user = API.ApproverUser(approverStates: [
        .init(
            participantId: .random(),
            phase: .complete,
            ownerLabel: "Anton"
        ),
        .init(
            participantId: .random(),
            phase: .complete,
            ownerLabel: "John Doe"
        )
    ])
    
    return NavigationView {
        OwnerLoginIdReset(
            session: .sample,
            user: $user
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
