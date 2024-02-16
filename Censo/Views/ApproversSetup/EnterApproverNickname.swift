//
//  EnterApproverNickname.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI
import Sentry

struct EnterApproverNickname: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var policySetup: API.PolicySetup?
    var isPrimary: Bool
    var onBack: (() -> Void)?
    
    @StateObject private var nickname = ApproverNickname()
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            Text("Give your approver a unique nickname so you can identify them.")
                .font(.subheadline)
                .padding(.bottom)

            VStack(spacing: 0) {
                TextField(text: $nickname.value) {
                    Text("Enter a nickname...")
                }
                .textFieldStyle(RoundedTextFieldStyle())
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                Text(nickname.isTooLong ? "Can't be longer than \(nickname.limit) characters" : " ")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.red)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom)
            
            Button {
                submit()
            } label: {
                Group {
                    if submitting {
                        ProgressView()
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .disabled(submitting || !nickname.isValid)
        }
        .errorAlert(isPresented: $showingError, presenting: error)
        .padding([.leading, .trailing], 32)
        .navigationInlineTitle("Name your \(isPrimary ? "first" : "second") approver")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if let onBack {
                    DismissButton(icon: .back, action: onBack)
                } else {
                    DismissButton(icon: .close)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.submitting = false
        self.error = error
        self.showingError = true
    }
    
    private func submit() {
        self.submitting = true
            
        do {
            let newApproverParticipantId = ParticipantId.random()
            let approvers: [API.ApproverSetup]
            
            if let owner = policySetup?.approvers.first,
               let primaryApprover = policySetup?.approvers.last {
                approvers = [
                    .ownerAsApprover(API.ApproverSetup.OwnerAsApprover(
                        participantId: owner.participantId,
                        label: "Me"
                    )),
                    .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: primaryApprover.participantId,
                        label: primaryApprover.label,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: ownerRepository.deviceKey)
                    )),
                    .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: newApproverParticipantId,
                        label: nickname.value,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: ownerRepository.deviceKey)
                    ))
                ]
            } else {
                let ownerParticipantId = ParticipantId.random()
                approvers = [
                    .ownerAsApprover(API.ApproverSetup.OwnerAsApprover(
                        participantId: ownerParticipantId,
                        label: "Me"
                    )),
                    .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: newApproverParticipantId,
                        label: nickname.value,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: ownerRepository.deviceKey)
                    ))
                ]
            }
            
            ownerRepository.setupPolicy(API.SetupPolicyApiRequest(threshold: 2, approvers: approvers)) { result in
                switch result {
                case .success(let response):
                    ownerStateStoreController.replace(response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            SentrySDK.captureWithTag(error: error, tagValue: "Setup policy")
            showError(CensoError.failedToSaveApproversName)
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            ApproversSetup(
                ownerState: API.OwnerState.Ready(
                    policy: .sample,
                    vault: .sample,
                    policySetup: nil,
                    authType: .facetec,
                    subscriptionStatus: .active,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: false
                )
            )
        }
    }
}
#endif
