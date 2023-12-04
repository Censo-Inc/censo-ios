//
//  ApproversSetup.swift
//  Censo
//
//  Created by Anton Onyshchenko on 19.10.23.
//

import Foundation
import SwiftUI
import Moya
import raygun4apple

struct ApproversSetup: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case setupPrimary
        case proposeAlternate
        case setupAlternate
        case cancellingAlternate
        case replacingPolicy
        case done
        
        static func fromOwnerState(_ ownerState: API.OwnerState.Ready) -> Step {
            if ownerState.policySetup?.alternateApprover == nil {
                if ownerState.policySetup?.primaryApprover?.isConfirmed == true {
                    return .proposeAlternate
                } else {
                    return .setupPrimary
                }
            } else {
                return .setupAlternate
            }
        }
    }
    
    @State private var step: Step
    @State private var proposeToAddAlternateApprover = false
    @State private var showingError = false
    @State private var error: Error?
    
    init(session: Session, ownerState: API.OwnerState.Ready, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void, step: Step) {
        self.session = session
        self.ownerState = ownerState
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: step)
    }
    
    init(session: Session, ownerState: API.OwnerState.Ready, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.ownerState = ownerState
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: Step.fromOwnerState(ownerState))
    }
    
    var body: some View {
        switch (step) {
        case .setupPrimary:
            SetupApprover(
                session: session,
                policySetup: ownerState.policySetup,
                isPrimary: true,
                onComplete: {
                    step = .proposeAlternate
                },
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        case .proposeAlternate:
            ProposeToAddAlternateApprover(
                onAccept: {
                    step = .setupAlternate
                },
                onSkip: {
                    step = .replacingPolicy
                }
            )
        case .setupAlternate:
            SetupApprover(
                session: session,
                policySetup: ownerState.policySetup,
                isPrimary: false,
                onComplete: {
                    step = .replacingPolicy
                },
                onOwnerStateUpdated: onOwnerStateUpdated,
                onBack: {
                    cancelAlternateApproverSetup()
                }
            )
        case .cancellingAlternate:
            ProgressView()
                .navigationBarTitleDisplayMode(.inline)
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        showingError = false
                        error = nil
                        self.step = Step.fromOwnerState(ownerState)
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
        case .replacingPolicy:
            ReplacePolicy(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated,
                onSuccess: { ownerState in
                    onOwnerStateUpdated(ownerState)
                    self.step = .done
                },
                onCanceled: {
                    dismiss()
                },
                intent: .setupApprovers
            )
        case .done:
            ApproversSetupDone(text: "Activated")
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        dismiss()
                    }
                })
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    func cancelAlternateApproverSetup() {
        self.step = .cancellingAlternate
            
        do {
            let policySetup = ownerState.policySetup!
            let owner = policySetup.owner!
            let primaryApprover = policySetup.primaryApprover!
            let guardians: [API.GuardianSetup] = [
                .implicitlyOwner(API.GuardianSetup.ImplicitlyOwner(
                    participantId: owner.participantId,
                    label: "Me",
                    guardianPublicKey: try session.getOrCreateApproverKey(participantId: owner.participantId).publicExternalRepresentation()
                )),
                .externalApprover(API.GuardianSetup.ExternalApprover(
                    participantId: primaryApprover.participantId,
                    label: primaryApprover.label,
                    deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                ))
            ]
            
            apiProvider.decodableRequest(
                with: session,
                endpoint: .setupPolicy(API.SetupPolicyApiRequest(threshold: 2, guardians: guardians))
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdated(response.ownerState)
                    step = .proposeAlternate
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            RaygunClient.sharedInstance().send(error: error, tags: ["Setup policy"], customData: nil)
            showError(CensoError.failedToCancelAlternateApproverSetup)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ApproversSetup(
            session: Session.sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                guardianSetup: policySetup,
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
