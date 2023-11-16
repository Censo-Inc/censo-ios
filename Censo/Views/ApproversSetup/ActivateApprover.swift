//
//  ActivateApprover.swift
//  Censo
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
    var onBack: (() -> Void)?
    
    enum Mode {
        case getLive
        case activate
        case rename
    }
    
    @State private var mode: Mode = .getLive
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        let isPrimary = approver == policySetup.primaryApprover
        
        switch(mode) {
        case .getLive:
            GetLiveWithApprover(
                approverName: approver.label,
                onContinue: {
                    mode = .activate
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let onBack {
                        Button {
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                    }
                }
            })
        case .rename:
            RenameApprover(
                session: session,
                policySetup: policySetup,
                approver: approver,
                onComplete: { ownerState in
                    onOwnerStateUpdated(ownerState)
                    mode = .activate
                }
            )
            .navigationTitle(Text("Activate \(approver.label)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        mode = .activate
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            })
        case .activate:
            ScrollView {
                Text("Activate \(approver.label)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 20) {
                        ShareLink(
                            item: Configuration.approverAppURL
                        ) {
                            ZStack(alignment: .topLeading) {
                                Text("1")
                                    .font(.system(size: 12))
                                    .tint(.black)
                                    .padding(7)
                                Image("Export")
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .padding(8)
                                    .background(.gray.opacity(0.25))
                                    .clipShape(RoundedRectangle(cornerRadius: 16.0))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16.0)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("1. Share app link")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom)
                            
                            Text("Share the app link with \(approver.label) and have \(approver.label) download the Censo Approver app from the Apple App store or Google Play store.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    HStack(alignment: .top) {
                        if let invitationId = approver.invitationId {
                            ShareLink(
                                item: invitationId.url
                            ) {
                                ZStack(alignment: .topLeading) {
                                    Text("2")
                                        .font(.system(size: 12))
                                        .tint(.black)
                                        .padding(7)
                                    Image("Export")
                                        .resizable()
                                        .frame(width: 48, height: 48)
                                        .padding(8)
                                        .background(.gray.opacity(0.25))
                                        .clipShape(RoundedRectangle(cornerRadius: 16.0))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16.0)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                        .padding(.trailing)
                                }
                            }
                        } else {
                            EmptyView()
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("2. Share invitation link")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom)
                            
                            Text("After \(approver.label) has installed the Censo Approver app, share this invitation link and have \(approver.label) tap on it or paste it into the Censo Approver app.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "waveform")
                            .resizable()
                            .frame(width: 48, height: 32)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 16)
                            .background(.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .padding(.trailing)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("3. Read authentication code")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom)
                            
                            if let deviceEncryptedTotpSecret = approver.deviceEncryptedTotpSecret {
                                Text("Read aloud this code and have \(approver.label) enter it into the Censo Approver app to authenticate to you.")
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                RotatingTotpPinView(
                                    session: session,
                                    deviceEncryptedTotpSecret: deviceEncryptedTotpSecret,
                                    style: .owner
                                )
                            } else if approver.isConfirmed {
                                Text("\(approver.label) is now activated!")
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("As soon as \(approver.label) accepts the invitation, a code will appear here. Read aloud this code and have \(approver.label) enter it into the Censo Approver app to authenticate to you.")
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .padding([.leading, .trailing], 32)
                
                Spacer()

                VStack(spacing: 0) {
                    Divider()
                        .padding(.bottom)

                    ApproverPill(
                        isPrimary: isPrimary,
                        approver: .prospect(approver),
                        onEdit: { mode = .rename },
                        onVerificationSubmitted: { status in
                            confirmApprover(
                                participantId: approver.participantId,
                                status: status
                            )
                        }
                    )
                    .padding(.bottom)
                    
                    Button {
                        onComplete()
                    } label: {
                        Text("Continue")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.bottom)
                    .disabled(!approver.isConfirmed)
                }
                .padding([.leading, .trailing], 32)
            }
            .padding([.top], 24)
            .navigationTitle(Text(isPrimary ? "Add Approver" : "Add Second Approver"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        mode = .getLive
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
                        keyConfirmationSignature: signature,
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
