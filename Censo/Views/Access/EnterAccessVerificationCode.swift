//
//  EnterAccessVerificationCode.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.10.23.
//

import Foundation
import SwiftUI
import Moya
import Sentry

struct EnterAccessVerificationCode : View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var policy: API.Policy
    var approval: API.Access.ThisDevice.Approval
    var approver: API.TrustedApprover
    
    var intent: API.Access.Intent
    var onSuccess: (API.OwnerState) -> Void
    
    @State private var verificationCode: [Int] = []
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        VStack(spacing: 0) {
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
                            .frame(minHeight: 40)
                            .frame(maxWidth: 3, maxHeight: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step 1: Share this link")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Share this link and have \(approver.label) click it or paste into their Approver app.")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                        
                        if let link = URL(string: "\(Configuration.approverUrlScheme)://access/v2/\(approver.participantId.value)/\(approval.approvalId)") {
                            ShareLink(
                                item: link
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
                            .padding(.bottom)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                HStack(alignment: .top) {
                    Image("PhoneWaveform")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.horizontal, 8)

                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step 2: Enter the Code")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                            Text("Have \(approver.label) read aloud the 6-digit code from their Approver app and enter it below.")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
            
            VStack(spacing: 0) {
                if approval.status == .initial {
                    ProgressView("Waiting for \(approver.label) to open the link")
                } else {
                    if approval.status == .rejected {
                        Text(CensoError.verificationFailed.localizedDescription)
                            .bold()
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    VerificationCodeEntry(
                        pinInput: $verificationCode,
                        disabled: submitting || !(approval.status == .waitingForVerification || approval.status == .rejected)
                    )
                    .onChange(of: verificationCode) { _ in
                        if (verificationCode.count == 6) {
                            submitVerificationCode(
                                verificationCode.map({ digit in String(digit) }).joined()
                            )
                        }
                    }
                    
                    if submitting || approval.status == .waitingForApproval {
                        ProgressView(
                            "Waiting for \(approver.label) to verify the code"
                        ).multilineTextAlignment(.center)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical)
        .padding(.horizontal)
        .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: refreshState, isIdleTimerDisabled: true))
        .onReceive(remoteNotificationPublisher) { _ in
            refreshState()
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: {
                Text("OK")
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func refreshState() {
        ownerRepository.getUser { result in
            switch result {
            case .success(let user):
                if let access = user.ownerState.thisDeviceAccess,
                   let approval = access.approvals.first(where: { $0.participantId == approver.participantId }) {
                    if approval.status == .approved {
                        onSuccess(user.ownerState)
                    } else {
                        ownerStateStoreController.replace(user.ownerState)
                    }
                } else {
                    ownerStateStoreController.replace(user.ownerState)
                }
            default:
                break
            }
        }
    }
    
    private func submitVerificationCode(_ code: String) {
        submitting = true
        let deviceKey = ownerRepository.deviceKey
        guard let (timeMillis, signature) = TotpUtils.signCode(code: code, signingKey: deviceKey),
              let devicePublicKey = try? Base58EncodedPublicKey(data: deviceKey.publicExternalRepresentation())
        else {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateSignature, tagValue: "Verification")
            self.error = CensoError.failedToCreateSignature
            self.submitting = false
            return
        }
        
        self.error = nil
        
        ownerRepository.submitAccessTotpVerification(
            approver.participantId,
            API.SubmitAccessTotpVerificationApiRequest(
                signature: signature,
                timeMillis: timeMillis,
                ownerDevicePublicKey: devicePublicKey
            )
        ) { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure(let error):
                self.error = error
            }
            self.submitting = false
        }
    }
}

#if DEBUG
#Preview("initial") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            let policy = API.Policy.sample2Approvers
            let approver = policy.approvers.last!
            
            EnterAccessVerificationCode(
                policy: policy,
                approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .initial),
                approver: approver,
                intent: .accessPhrases,
                onSuccess: { _ in }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("entercode") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            let policy = API.Policy.sample2Approvers
            let approver = policy.approvers.last!
            
            EnterAccessVerificationCode(
                policy: policy,
                approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .waitingForVerification),
                approver: approver,
                intent: .accessPhrases,
                onSuccess: { _ in }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("rejected") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            let policy = API.Policy.sample2Approvers
            let approver = policy.approvers.last!
            
            EnterAccessVerificationCode(
                policy: policy,
                approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .rejected),
                approver: approver,
                intent: .accessPhrases,
                onSuccess: { _ in }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("waiting") {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            let policy = API.Policy.sample2Approvers
            let approver = policy.approvers.last!
            
            EnterAccessVerificationCode(
                policy: policy,
                approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .waitingForApproval),
                approver: approver,
                intent: .accessPhrases,
                onSuccess: { _ in }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
