//
//  RenameApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 26.10.23.
//

import Foundation
import SwiftUI
import Sentry

struct RenameApprover: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var policySetup: API.PolicySetup
    var approver: API.ProspectApprover
    var onComplete: () -> Void
    
    @StateObject private var newName = ApproverNickname()
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    init(policySetup: API.PolicySetup, approver: API.ProspectApprover, onComplete: @escaping () -> Void) {
        self.policySetup = policySetup
        self.approver = approver
        self.onComplete = onComplete
        self._newName = StateObject(wrappedValue: ApproverNickname(approver.label))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                TextField(text: $newName.value) {}
                .textFieldStyle(RoundedTextFieldStyle())
                .font(.title2)
                .frame(maxWidth: .infinity)
                
                Text(newName.isTooLong ? "Can't be longer than \(newName.limit) characters" : " ")
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
                        Text("Save")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .disabled(submitting || !newName.isValid)
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
        .padding([.leading, .trailing], 32)
    }
    
    private func showError(_ error: Error) {
        self.submitting = false
        self.error = error
        self.showingError = true
    }
    
    private func submit() {
        self.submitting = true
        let approverToRename = approver
            
        do {
            let approvers: [API.ApproverSetup] = try policySetup.approvers.enumerated().map({ (index, approver) in
                if index == 0 {
                    return .ownerAsApprover(API.ApproverSetup.OwnerAsApprover(
                        participantId: approver.participantId,
                        label: "Me"
                    ))
                } else {
                    return .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: approver.participantId,
                        label: approver.participantId == approverToRename.participantId ? newName.value : approver.label,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: ownerRepository.deviceKey)
                    ))
                }
            })
            
            ownerRepository.setupPolicy(
                API.SetupPolicyApiRequest(threshold: 2, approvers: approvers)
            ) { result in
                switch result {
                case .success(let response):
                    ownerStateStoreController.replace(response.ownerState)
                    onComplete()
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
            RenameApprover(
                policySetup: policySetup,
                approver: policySetup.approvers[1],
                onComplete: {}
            )
            .navigationTitle(Text("Activate Neo"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
        }
    }
}
#endif
