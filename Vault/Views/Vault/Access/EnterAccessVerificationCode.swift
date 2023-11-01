//
//  EnterAccessVerificationCode.swift
//  Vault
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
    var approval: API.Recovery.ThisDevice.Approval
    var approver: API.TrustedGuardian
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
            VStack(spacing: 10) {
                Text("Request access")
                    .font(.system(size: 24))
                    .bold()
                
                Text("Your approver must do three things:")
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
                        Text("1. Open the app")
                            .font(.system(size: 18))
                            .bold()
                        
                        Text("They must download Censo Approver App from the Apple or Android App stores.")
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let url = URL(string: "https://censo.co/approvers") {
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
                        Text("2. Open unique link")
                            .font(.system(size: 18))
                            .bold()
                        
                        Text("After they have installed Censo, send them this unique, secret link.")
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let link = URL(string: "\(Configuration.approverUrlScheme)://access/\(approver.participantId.value)") {
                            ShareLink(
                                item: link
                            ) {
                                Text("Share unique link")
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.white)
                                    .background(Color.black)
                                    .cornerRadius(100.0)
                            }.onAppear {
                                print(link)
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
                        Text("3. Enter the code")
                            .font(.system(size: 18))
                            .bold()
                        
                        Text("Enter the 6-digit code from your approver.")
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding([.bottom], 24)
            
            VStack(spacing: 0) {
                if approval.status == .initial {
                    ProgressView("Waiting for approver to open the link")
                } else {
                    if approval.status == .rejected {
                        Text(CensoError.verificationFailed.localizedDescription)
                            .bold()
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14))
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
        .padding([.top], 24)
        .padding(.horizontal, 32)
        .onReceive(remoteNotificationPublisher) { _ in
            refreshState()
        }
        .onReceive(refreshStatePublisher) { _ in
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
                if let recovery = user.ownerState.thisDeviceRecovery,
                   let approval = recovery.approvals.first(where: { $0.participantId == approver.participantId }) {
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
            endpoint: .submitRecoveryTotpVerification(
                participantId: approver.participantId,
                payload: API.SubmitRecoveryTotpVerificationApiRequest(
                    signature: signature,
                    timeMillis: timeMillis,
                    ownerDevicePublicKey: devicePublicKey
                )
            )
        ) { (result: Result<API.SubmitRecoveryTotpVerificationApiResponse, MoyaError>) in
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
#Preview {
    NavigationView {
        let policy = API.Policy.sample2Approvers
        let approver = policy.guardians.last!
        
        EnterAccessVerificationCode(
            session: .sample,
            policy: policy,
            approval: API.Recovery.ThisDevice.Approval(participantId: approver.participantId, status: .initial),
            approver: approver,
            onOwnerStateUpdated: { _ in },
            onSuccess: { _ in }
        )
    }
}
#endif