//
//  ApproverActivation.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-05.
//

import SwiftUI
import Moya

struct ApproverActivation: View {
    @Environment(\.apiProvider) private var apiProvider

    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)

    var session: Session
    var guardianSetup: API.OwnerState.GuardianSetup
    var onOwnerStateUpdate: (API.OwnerState) -> Void

    var body: some View {
        ScrollView {
            VStack {
                Text("Activate Approvers")
                    .font(.title2)
                    .padding()
                    .foregroundColor(.Censo.darkBlue)

                InfoBoard {
                    Text(
                        """
                        Now activate your approvers. The best way to do it is by visiting or calling them.

                        Once you’re in contact use the share link next to their nickname to send them a link to download the Approver app.

                        Once they login to their Approver app read them the digit number that will appear next to their nickname and that will complete their activation.
                        """
                    )
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 8) {
                    ForEach(guardianSetup.guardians, id: \.participantId) { guardian in
                        ApproverActivationRow(session: session, prospectGuardian: guardian, onOwnerStateUpdate: onOwnerStateUpdate)
                    }
                }
            }
        }
        .onReceive(remoteNotificationPublisher) { _ in
            reloadUser()
        }
        .onReceive(refreshStatePublisher) { _ in
            reloadUser()
        }
    }

    private func reloadUser() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdate(user.ownerState)
            default:
                break
            }
        }
    }
}

#if DEBUG
struct ApproverActivation_Previews: PreviewProvider {
    static var previews: some View {
        OpenVault {
            ApproverActivation(session: .sample, guardianSetup: .sample, onOwnerStateUpdate: { _ in })
        }
    }
}

extension API.OwnerState.GuardianSetup {
    static var sample: Self {
        .init(guardians: [.sample], threshold: 2)
    }
}

extension API.ProspectGuardian {
    static var sample: Self {
        .init(label: "Jerry", participantId: .random(), status: .declined)
    }
}
#endif
