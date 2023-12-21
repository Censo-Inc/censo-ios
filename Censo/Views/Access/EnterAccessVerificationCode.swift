//
//  EnterAccessVerificationCode.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.10.23.
//

import Foundation
import SwiftUI
import Moya
import raygun4apple

struct EnterAccessVerificationCode : View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var policy: API.Policy
    var approval: API.Access.ThisDevice.Approval
    var approver: API.TrustedApprover
    var intent: API.Access.Intent
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    var onSuccess: (API.OwnerState) -> Void
    
    @State private var verificationCode: [Int] = []
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        ScrollView {
            VStack {
                let title = switch (intent) {
                case .accessPhrases: "Request access"
                case .replacePolicy: "Request approval"
                }
                
                Text(title)
                    .font(.title)
                    .bold()
                
            }
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
                        Text("Share this link")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Share this link and have \(approver.label) click it or paste into their Approver app.")
                            .font(.headline)
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
                        Text("Step 2:")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Enter the Code")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.bottom, 2)
                        
    
                            Text("Have \(approver.label) read aloud the 6-digit code from their Approver app and enter it below.")
                                .font(.headline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding([.bottom], 24)
            
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
                        ProgressView()
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
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
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                if let access = user.ownerState.thisDeviceAccess,
                   let approval = access.approvals.first(where: { $0.participantId == approver.participantId }) {
                    if approval.status == .approved {
                        onSuccess(user.ownerState)
                    } else {
                        onOwnerStateUpdated(user.ownerState)
                    }
                } else {
                    onOwnerStateUpdated(user.ownerState)
                }
            default:
                break
            }
        }
    }
    
    private func submitVerificationCode(_ code: String) {
        submitting = true
        let deviceKey = session.deviceKey
        guard let (timeMillis, signature) = TotpUtils.signCode(code: code, signingKey: deviceKey),
              let devicePublicKey = try? Base58EncodedPublicKey(data: deviceKey.publicExternalRepresentation())
        else {
            RaygunClient.sharedInstance().send(error: CensoError.failedToCreateSignature, tags: ["Verification"], customData: nil)
            self.error = CensoError.failedToCreateSignature
            self.submitting = false
            return
        }
        
        self.error = nil
        
        apiProvider.decodableRequest(
            with: session,
            endpoint: .submitAccessTotpVerification(
                participantId: approver.participantId,
                payload: API.SubmitAccessTotpVerificationApiRequest(
                    signature: signature,
                    timeMillis: timeMillis,
                    ownerDevicePublicKey: devicePublicKey
                )
            )
        ) { (result: Result<API.SubmitAccessTotpVerificationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                self.error = error
            }
            self.submitting = false
        }
    }
}

#if DEBUG
#Preview("initial") {
    NavigationView {
        let policy = API.Policy.sample2Approvers
        let approver = policy.approvers.last!
        
        EnterAccessVerificationCode(
            session: .sample,
            policy: policy,
            approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .initial),
            approver: approver,
            intent: .accessPhrases,
            onOwnerStateUpdated: { _ in },
            onSuccess: { _ in }
        ).foregroundColor(.Censo.primaryForeground)
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("entercode") {
    NavigationView {
        let policy = API.Policy.sample2Approvers
        let approver = policy.approvers.last!
        
        EnterAccessVerificationCode(
            session: .sample,
            policy: policy,
            approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .waitingForVerification),
            approver: approver,
            intent: .accessPhrases,
            onOwnerStateUpdated: { _ in },
            onSuccess: { _ in }
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
    }.foregroundColor(.Censo.primaryForeground)
}

#Preview("rejected") {
    NavigationView {
        let policy = API.Policy.sample2Approvers
        let approver = policy.approvers.last!
        
        EnterAccessVerificationCode(
            session: .sample,
            policy: policy,
            approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .rejected),
            approver: approver,
            intent: .accessPhrases,
            onOwnerStateUpdated: { _ in },
            onSuccess: { _ in }
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
    }.foregroundColor(.Censo.primaryForeground)
}

#Preview("waiting") {
    NavigationView {
        let policy = API.Policy.sample2Approvers
        let approver = policy.approvers.last!
        
        EnterAccessVerificationCode(
            session: .sample,
            policy: policy,
            approval: API.Access.ThisDevice.Approval(participantId: approver.participantId, approvalId: "approval_id", status: .waitingForApproval),
            approver: approver,
            intent: .accessPhrases,
            onOwnerStateUpdated: { _ in },
            onSuccess: { _ in }
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
    }.foregroundColor(.Censo.primaryForeground)
}
#endif
