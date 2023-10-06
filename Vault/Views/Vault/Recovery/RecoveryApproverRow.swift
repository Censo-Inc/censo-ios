//
//  RecoveryApproverRow.swift
//  Vault
//
//  Created by Anton Onyshchenko on 05.10.23.
//

import Foundation
import SwiftUI
import Moya

struct RecoveryApproverRow : View {
    var session: Session
    var guardian: API.TrustedGuardian
    var approval: API.Recovery.ThisDevice.Approval
    var reloadUser: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showEnterCodeModal = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            VStack(spacing: 5) {
                HStack(spacing: 0) {
                    Text("Status: ")
                        .font(.system(size: 16))
                        .foregroundColor(Color.Censo.lightGray)
                    ApprovalStatus(status: approval.status)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(guardian.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 24).bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if approval.status == .initial {
                if let link = URL(string: "censo-guardian://recovery/\(guardian.participantId.value)") {
                    ShareLink(item: link,
                              subject: Text("Censo Recovery Link for \(guardian.label)"),
                              message: Text("Censo Recovery Link for \(guardian.label)")
                    ){
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.black, .white)
                            .font(.system(size: 28))
                    }
                }
            } else if approval.status == .waitingForVerification || approval.status == .rejected {
                Button {
                    showEnterCodeModal = true
                } label: {
                    Text("Enter Code")
                }
                .buttonStyle(FilledButtonStyle(tint: .light))
            } else if approval.status == .approved {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.Censo.green)
                    .font(.system(size: 28))
                    .onAppear {
                        showEnterCodeModal = false
                    }
            }
        }
        .frame(height: 64)
        .listRowBackground(Color.white.opacity(0.05))
        .listRowSeparatorTint(.white)
        .sheet(isPresented: $showEnterCodeModal) {
            EnterCodeModal(
                session: session,
                approverLabel: guardian.label,
                participantId: guardian.participantId,
                approvalStatus: approval.status,
                reloadUser: reloadUser,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        }
    }
    
    struct ApprovalStatus : View {
        var status: API.Recovery.ThisDevice.Approval.Status
        
        var body: some View {
            switch (status) {
            case .initial:
                Text("Pending")
                    .font(.system(size: 16).bold())
                    .foregroundColor(Color.Censo.lightGray)
            case .waitingForVerification:
                Text("Awaiting Code")
                    .font(.system(size: 16).bold())
                    .foregroundColor(.white)
            case .waitingForApproval:
                Text("Verifying")
                    .font(.system(size: 16).bold())
                    .foregroundColor(.white)
            case .approved:
                Text("Approved")
                    .font(.system(size: 16).bold())
                    .foregroundColor(Color.Censo.green)
            case .rejected:
                Text("Incorrect Code")
                    .font(.system(size: 16).bold())
                    .foregroundColor(Color.Censo.red)
            }
        }
    }
    
    struct EnterCodeModal: View {
        @Environment(\.apiProvider) var apiProvider
        @Environment(\.presentationMode) var presentation
        
        var session: Session
        var approverLabel: String
        var participantId: ParticipantId
        var approvalStatus: API.Recovery.ThisDevice.Approval.Status
        var reloadUser: () -> Void
        var onOwnerStateUpdated: (API.OwnerState) -> Void
        
        @State private var verificationCode: [Int] = []
        @State private var submitting = false
        @State private var error: Error?

        let waitingForApproval = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        
        var body: some View {
            VStack {
                Text("Please enter the 6 digit code provided by \(approverLabel)")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VerificationCodeEntry(pinInput: $verificationCode)
                    .onChange(of: verificationCode) { _ in
                        if (verificationCode.count == 6) {
                            submitVerificationCode(
                                verificationCode.map({ digit in String(digit) }).joined()
                            )
                        }
                    }
                    .disabled(
                        approvalStatus == .waitingForApproval || submitting == true
                    )
                
                if (error == nil) {
                    switch (approvalStatus) {
                    case .waitingForApproval:
                        ProgressView(
                            label: {
                                Text("Waiting for approver to verify the code.")
                            }
                        ).onReceive(waitingForApproval) { _ in
                            reloadUser()
                        }
                    case .rejected:
                        Text(CensoError.verificationFailed.localizedDescription)
                            .bold()
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                        
                        Button("Dismiss") {
                            self.presentation.wrappedValue.dismiss()
                        }
                    default:
                        EmptyView()
                        
                        Button("Dismiss") {
                            self.presentation.wrappedValue.dismiss()
                        }
                    }
                } else {
                    Text(error!.localizedDescription)
                        .bold()
                        .foregroundColor(Color.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        
        private func submitVerificationCode(_ code: String) {
            submitting = true
            let deviceKey = session.deviceKey
            
            let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
            
            guard let codeBytes = code.data(using: .utf8),
                  let timeMillisData = String(timeMillis).data(using: .utf8),
                  let devicePublicKey = try? Base58EncodedPublicKey(data: deviceKey.publicExternalRepresentation()),
                  let signature = try? Base64EncodedString(data: deviceKey.signature(for: codeBytes + timeMillisData))
            else {
                self.error = CensoError.failedToCreateSignature
                self.submitting = false
                return
            }
            
            self.error = nil
            
            apiProvider.decodableRequest(
                with: session,
                endpoint: .submitRecoveryTotpVerification(
                    participantId: participantId,
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
}

