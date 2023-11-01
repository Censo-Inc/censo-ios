//
//  RenameApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 26.10.23.
//

import Foundation
import SwiftUI
import Moya
import raygun4apple

struct RenameApprover: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var policySetup: API.PolicySetup
    var approver: API.ProspectGuardian
    var onComplete: (API.OwnerState) -> Void
    
    @State private var newName: String
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    init(session: Session, policySetup: API.PolicySetup, approver: API.ProspectGuardian, onComplete: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.policySetup = policySetup
        self.approver = approver
        self.onComplete = onComplete
        self._newName = State(initialValue: approver.label)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            Text("Rename approver")
                .font(.system(size: 24))
                .bold()
            
            TextField(text: $newName) {}
                .textFieldStyle(RoundedTextFieldStyle())
                .font(.system(size: 24))
                .frame(maxWidth: .infinity)
            
            Button {
                submit()
            } label: {
                Group {
                    if submitting {
                        ProgressView()
                    } else {
                        Text("Save")
                            .font(.system(size: 24))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(submitting || newName.trimmingCharacters(in: .whitespaces).isEmpty)
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
            let guardians: [API.GuardianSetup] = try policySetup.guardians.enumerated().map({ (index, approver) in
                if index == 0 {
                    return .implicitlyOwner(API.GuardianSetup.ImplicitlyOwner(
                        participantId: approver.participantId,
                        label: "Me",
                        guardianPublicKey: try session.getOrCreateApproverKey(participantId: approver.participantId).publicExternalRepresentation()
                    ))
                } else {
                    return .externalApprover(API.GuardianSetup.ExternalApprover(
                        participantId: approver.participantId,
                        label: approver.participantId == approverToRename.participantId ? newName : approver.label,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    ))
                }
            })
            
            apiProvider.decodableRequest(
                with: session,
                endpoint: .setupPolicy(API.SetupPolicyApiRequest(threshold: 2, guardians: guardians))
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onComplete(response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            RaygunClient.sharedInstance().send(error: error, tags: ["Setup policy"], customData: nil)
            showError(CensoError.failedToSaveApproversName)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        RenameApprover(
            session: .sample,
            policySetup: policySetup,
            approver: policySetup.guardians[1],
            onComplete: { _ in }
        )
    }
}
#endif
