//
//  ActivateApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct ActivateApprover : View {
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
        switch(mode) {
        case .getLive:
            GetLive(
                name: approver.label,
                onContinue: {
                    mode = .activate
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let onBack {
                        DismissButton(icon: .back, action: onBack)
                    } else {
                        DismissButton(icon: .close)
                    }
                }
            }
        case .rename:
            RenameApprover(
                policySetup: policySetup,
                approver: approver,
                onComplete: { 
                    mode = .activate
                }
            )
            .navigationInlineTitle("Rename approver")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .back, action: {
                        mode = .activate
                    })
                }
            }
        case .activate:
            VStack {
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
                                .frame(minHeight: 20)
                                .frame(maxWidth: 3, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Step 1: Share Approver App")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.bottom, 2)
                            
                            Text("Share this link so \(approver.label) can download the Censo Approver app")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            ShareLink(
                                item: Configuration.approverAppURL
                            ) {
                                HStack(spacing: 0) {
                                    Image("Export")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 6)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .bold()
                                    Text("Share")
                                        .font(.headline)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .padding(.trailing)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .frame(width: 128)
                                )
                            }
                            .padding(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
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
                                .frame(minHeight: 20)
                                .frame(maxWidth: 3, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Step 2: Share Invite Link")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.bottom, 2)
                            
                            Text("Share this link and have \(approver.label) click it or paste into their Approver app")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let invitationId = approver.invitationId {
                                ShareLink(
                                    item: invitationId.url
                                ) {
                                    HStack(spacing: 0) {
                                        Image("Export")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 6)
                                            .foregroundColor(.Censo.aquaBlue)
                                        Text("Invite")
                                            .font(.headline)
                                            .foregroundColor(.Censo.aquaBlue)
                                            .padding(.trailing)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .frame(width: 128)
                                    )
                                }
                                .padding(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    HStack(alignment: .top) {
                        Image("PhoneWaveform")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .padding(.horizontal, 8)
                        
                        VStack(alignment: .leading) {
                            Text("Step 3: Read Code")
                                .font(.headline)
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
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Read code that appears here and have \(approver.label) enter it in their Approver app")
                                    .font(.subheadline)
                                    .fontWeight(.regular)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.bottom)
                }
                .padding(.horizontal)
                
                Spacer()

                VStack(spacing: 0) {
                    Divider()

                    ApproverPill(
                        approver: .prospect(approver),
                        onEdit: { mode = .rename },
                        onVerificationSubmitted: { status in
                            confirmApprover(
                                participantId: approver.participantId,
                                status: status
                            )
                        }
                    )
                    .padding(.vertical)
                    
                    Button {
                        onComplete()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.bottom)
                    .disabled(!approver.isConfirmed)
                }
                .padding([.leading, .trailing], 32)
                .padding(.bottom)
            }
            .padding(.top)
            .navigationInlineTitle("Verify \(approver.label)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .back, action: {
                        mode = .getLive
                    })
                }
            }
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
        ProgressView()
            .sheet(isPresented: Binding.constant(true), content: {
                NavigationView {
                    ActivateApprover(
                        policySetup: policySetup,
                        approver: policySetup.approvers[1],
                        onComplete: { }
                    )
                }
            })
    }
}

#Preview("Activation Confirmed") {
    LoggedInOwnerPreviewContainer {
        ProgressView()
            .sheet(isPresented: Binding.constant(true), content: {
                NavigationView {
                    ActivateApprover(
                        policySetup: policySetup,
                        approver: policySetup.approvers[2],
                        onComplete: { }
                    )
                }
            })
    }
}
#endif
