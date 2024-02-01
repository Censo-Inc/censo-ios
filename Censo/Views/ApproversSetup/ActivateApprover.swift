//
//  ActivateApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct ActivateApprover : View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var policySetup: API.PolicySetup
    var approver: API.ProspectApprover
    var onComplete: () -> Void
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
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            })
        case .rename:
            RenameApprover(
                policySetup: policySetup,
                approver: approver,
                onComplete: { 
                    mode = .activate
                }
            )
            .navigationTitle(Text("Verify \(approver.label)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        mode = .activate
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
        case .activate:
            ScrollView {
                Text("Verify \(approver.label)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 20) {
                        VStack {
                            Image("CensoLogoDarkBlueStacked")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: 16.0))
                                .foregroundColor(.Censo.aquaBlue)
                                .background(
                                    RoundedRectangle(cornerRadius: 16.0)
                                )
                            
                            Rectangle()
                                .fill(Color.Censo.darkBlue)
                                .frame(maxWidth: 3, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Step 1:")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Share Approver App")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Share this link so \(approver.label) can download the Censo Approver app")
                                .font(.headline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 4)
                            
                            ShareLink(
                                item: Configuration.approverAppURL
                            ) {
                                HStack(spacing: 0) {
                                    Image("Export")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .bold()
                                    Text("Share")
                                        .font(.title3)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .padding(.trailing)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .frame(width: 128)
                                    )
                            }
                            .padding(.bottom)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    HStack(alignment: .top, spacing: 20) {
                        VStack {
                            Image("CensoLogoDarkBlueStacked")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: 16.0))
                                .foregroundColor(.Censo.darkBlue)
                                .background(
                                    RoundedRectangle(cornerRadius: 16.0)
                                        .fill(Color.Censo.aquaBlue)
                                )
                            Rectangle()
                                .fill(Color.Censo.darkBlue)
                                .frame(maxWidth: 3, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Step 2:")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Share Invite Link")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Share this link and have \(approver.label) click it or paste into their Approver app")
                                .font(.headline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 4)
                            
                            if let invitationId = approver.invitationId {
                                ShareLink(
                                    item: invitationId.url
                                ) {
                                    HStack(spacing: 0) {
                                        Image("Export")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 28, height: 28)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 8)
                                            .foregroundColor(.Censo.aquaBlue)
                                        Text("Invite")
                                            .font(.title3)
                                            .foregroundColor(.Censo.aquaBlue)
                                            .padding(.trailing)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .frame(width: 128)
                                    )
                                }
                                .padding(.bottom)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 5)
                    
                    
                    HStack(alignment: .top) {
                        Image("PhoneWaveform")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .padding(.horizontal, 8)

                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Step 3:")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Read Code")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom, 2)
                            
                            
                            if let deviceEncryptedTotpSecret = approver.deviceEncryptedTotpSecret,
                               let totpSecret = try? ownerRepository.deviceKey.decrypt(data: deviceEncryptedTotpSecret.data) {
                                RotatingTotpPinView(
                                    totpSecret: totpSecret,
                                    style: .owner
                                )
                            } else if approver.isConfirmed {
                                Text("\(approver.label) is now verified!")
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Read code that appears here and have \(approver.label) enter it in their Approver app")
                                    .font(.headline)
                                    .fontWeight(.regular)
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
                    }
                }
            })
            .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: refreshState, isIdleTimerDisabled: true))
            .onReceive(remoteNotificationPublisher) { _ in
                refreshState()
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func refreshState() {
        ownerStateStoreController.reload()
    }
    
    private func confirmApprover(participantId: ParticipantId, status: API.ApproverStatus.VerificationSubmitted) {
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
                  let signature = try? ownerRepository.deviceKey.signature(for: status.approverPublicKey.data + participantIdData + timeMillisData) else {
                confirmationSucceeded = false
                return
            }
            ownerRepository.confirmApprover(
                API.ConfirmApproverApiRequest(
                    participantId: participantId,
                    keyConfirmationSignature: signature,
                    keyConfirmationTimeMillis: timeMillis
                )
            ) { result in
                switch result {
                case .success(let response):
                    ownerStateStoreController.replace(response.ownerState)
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

    private func verifyApproverSignature(participantId: ParticipantId, status: API.ApproverStatus.VerificationSubmitted) throws -> Bool {
        guard let totpSecret = try? ownerRepository.deviceKey.decrypt(data: status.deviceEncryptedTotpSecret.data),
              let timeMillisBytes = String(status.timeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.approverPublicKey) else {
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
        ownerRepository.rejectApproverVerification(participantId) { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
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
    approvers: [
        API.ProspectApprover(
            invitationId: try! InvitationId(value: ""),
            label: "Me",
            participantId: .random(),
            status: API.ApproverStatus.initial(.init(
                deviceEncryptedTotpSecret: Base64EncodedString(data: Data())
            ))
        ),
        API.ProspectApprover(
            invitationId: try! InvitationId(value: ""),
            label: "Neo",
            participantId: .random(),
            status: API.ApproverStatus.initial(.init(
                deviceEncryptedTotpSecret: Base64EncodedString(data: Data())
            ))
        ),
        API.ProspectApprover(
            invitationId: try! InvitationId(value: ""),
            label: "John Wick",
            participantId: .random(),
            status: API.ApproverStatus.confirmed(.init(
                approverKeySignature: .sample,
                approverPublicKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"),
                timeMillis: 123,
                confirmedAt: Date.now
            ))
        )
    ],
    threshold: 2
)

#Preview("Activation Pending") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            let session = Session.sample
            
            ActivateApprover(
                policySetup: policySetup,
                approver: policySetup.approvers[1],
                onComplete: { }
            )
        }
    }
}

#Preview("Activation Confirmed") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            let session = Session.sample
            ActivateApprover(
                policySetup: policySetup,
                approver: policySetup.approvers[1],
                onComplete: { }
            )
        }
    }
}
#endif
