//
//  ActivateApprover.swift
//  Vault
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI
import Moya

struct ActivateApprover : View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var policySetup: API.PolicySetup
    var approver: API.ProspectGuardian
    var onComplete: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case getLive
        case activate
        case rename
    }
    
    @State private var step: Step = .getLive
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        let isPrimary = approver == policySetup.primaryApprover
        
        switch(step) {
        case .getLive:
            GetLiveWithApprover(
                approverName: approver.label,
                onContinue: {
                    step = .activate
                }
            )
        case .rename:
            RenameApprover(
                session: session,
                policySetup: policySetup,
                approver: approver,
                onComplete: { ownerState in
                    onOwnerStateUpdated(ownerState)
                    step = .activate
                }
            )
            .navigationTitle(Text("\(isPrimary ? "Primary" : "Backup") approver"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .activate
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            })
        case .activate:
            ScrollView {
                VStack(spacing: 10) {
                    Text("Activate \(isPrimary ? "primary": "backup") approver")
                        .font(.system(size: 24))
                        .bold()
                    
                    Text("Now, your approver must do three things:")
                        .font(.system(size: 14))
                }
                .padding([.leading, .trailing], 32)
                .padding([.bottom], 20)
                
                VStack(spacing: 32) {
                    HStack(alignment: .top) {
                        Image("Export")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .padding(8)
                            .background(.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .padding([.trailing], 10)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("1. Download the app")
                                .font(.system(size: 18))
                                .bold()
                            
                            Text("They must download Censo Approver App from the Apple or Android App stores.")
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let url = URL(string: "https://censo.co/") {
                                ShareLink(
                                    item: url
                                ) {
                                    Text("Share app link")
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Color.white)
                                        .background(Color.black)
                                        .cornerRadius(100.0)
                                }
                            } else {
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack(alignment: .top) {
                        Image("Export")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .padding(8)
                            .background(.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .padding([.trailing], 10)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("2. Share the link")
                                .font(.system(size: 18))
                                .bold()
                            
                            Text("After they have installed Censo, send them this unique, secret link.")
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let invitationId = approver.invitationId {
                                ShareLink(
                                    item: invitationId.url
                                ) {
                                    Text("Share unique link")
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Color.white)
                                        .background(Color.black)
                                        .cornerRadius(100.0)
                                }
                            } else {
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack(alignment: .top) {
                        Image("PhraseEntry")
                            .resizable()
                            .frame(width: 48, height: 32)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 16)
                            .background(.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .padding([.trailing], 10)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("3. Share the code")
                                .font(.system(size: 18))
                                .bold()
                            
                            if let deviceEncryptedTotpSecret = approver.deviceEncryptedTotpSecret {
                                Text("They must enter this 6-digit code to become your \(isPrimary ? "primary" : "backup") approver.")
                                    .font(.system(size: 14))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                RotatingTotpPinView(session: session, deviceEncryptedTotpSecret: deviceEncryptedTotpSecret)
                            } else if approver.isConfirmed {
                                Text("The verification code has been succesfully confirmed.")
                                    .font(.system(size: 14))
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("They will need to enter a 6-digit code to become your \(isPrimary ? "primary" : "backup") approver.")
                                    .font(.system(size: 14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding([.leading, .trailing], 32)
                .padding([.bottom], 8)
                
                Spacer()
                
                VStack(spacing: 30) {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(isPrimary ? "Primary": "Backup") approver")
                                .font(.system(size: 14))
                                .bold()
                            
                            HStack {
                                Text(approver.label)
                                    .font(.system(size: 24))
                                    .bold()
                                
                                Spacer()
                                
                                Button {
                                    step = .rename
                                } label: {
                                    Image("Pencil")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
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
                                        confirmApprover(participantId: approver.participantId, status: verificationSubmitted)
                                    }
                            case .confirmed:
                                Text("Activated")
                                    .foregroundColor(.Censo.green)
                            case .implicitlyOwner:
                                Text("")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16.0)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    
                    Button {
                        onComplete()
                    } label: {
                        Text(isPrimary ? "Continue": "Save & finish")
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .disabled(!approver.isConfirmed)
                }
                .padding([.leading, .trailing], 32)
            }
            .padding([.top], 24)
            .navigationTitle(Text("\(isPrimary ? "Primary" : "Backup") approver"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .getLive
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            })
            .onReceive(remoteNotificationPublisher) { _ in
                refreshState()
            }
            .onReceive(refreshStatePublisher) { _ in
                refreshState()
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func refreshState() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdated(user.ownerState)
            default:
                break
            }
        }
    }
    
    private func confirmApprover(participantId: ParticipantId, status: API.GuardianStatus.VerificationSubmitted) {
        var confirmationSucceeded = false
        do {
            confirmationSucceeded = try verifyApproverSignature(participantId: participantId, status: status)
        } catch {
            confirmationSucceeded = false
        }

        if confirmationSucceeded {
            let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
            guard let participantIdData = participantId.value.data(using: .hexadecimal),
                  let timeMillisData = String(timeMillis).data(using: .utf8),
                  let signature = try? session.deviceKey.signature(for: status.guardianPublicKey.data + participantIdData + timeMillisData) else {
                confirmationSucceeded = false
                return
            }
            apiProvider.decodableRequest(
                with: session,
                endpoint: .confirmGuardian(
                    API.ConfirmGuardianApiRequest(
                        participantId: participantId,
                        keyConfirmationSignature: Base64EncodedString(data: signature),
                        keyConfirmationTimeMillis: timeMillis
                    )
                )
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdated(response.ownerState)
                case .failure:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        confirmApprover(participantId: participantId, status: status) // keep trying
                    }
                }
            }
        } else {
            rejectApproverVerification(participantId: participantId)
        }
    }

    private func verifyApproverSignature(participantId: ParticipantId, status: API.GuardianStatus.VerificationSubmitted) throws -> Bool {
        guard let totpSecret = try? session.deviceKey.decrypt(data: status.deviceEncryptedTotpSecret.data),
              let timeMillisBytes = String(status.timeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.guardianPublicKey) else {
            return false
        }

        let acceptedDate = Date(timeIntervalSince1970: Double(status.timeMillis) / 1000.0)
        for date in [acceptedDate, acceptedDate - TotpUtils.period, acceptedDate + TotpUtils.period] {
            if let codeBytes = TotpUtils.getOTP(date: date, secret: totpSecret).data(using: .utf8) {
                if try publicKey.verifySignature(for: codeBytes + timeMillisBytes, signature: status.signature) {
                    return true
                }
            }
        }

        return false
    }
    
    private func rejectApproverVerification(participantId: ParticipantId) {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .rejectGuardianVerification(participantId)
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdated(response.ownerState)
                case .failure:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        rejectApproverVerification(participantId: participantId) // keep trying
                    }
                }
            }
    }
}

#if DEBUG
let policySetup = API.PolicySetup(
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
        ),
        API.ProspectGuardian(
            invitationId: try! InvitationId(value: ""),
            label: "John Wick",
            participantId: .random(),
            status: API.GuardianStatus.confirmed(.init(
                guardianKeySignature: .sample,
                guardianPublicKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"),
                timeMillis: 123,
                confirmedAt: Date.now
            ))
        )
    ],
    threshold: 2
)

#Preview("Activation Pending") {
    NavigationView {
        let session = Session.sample
        
        ActivateApprover(
            session: session,
            policySetup: policySetup,
            approver: policySetup.guardians[1],
            onComplete: { },
            onOwnerStateUpdated: { _ in }
        )
    }
}

#Preview("Activation Confirmed") {
    NavigationView {
        let session = Session.sample
        ActivateApprover(
            session: session,
            policySetup: policySetup,
            approver: policySetup.guardians[1],
            onComplete: { },
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
