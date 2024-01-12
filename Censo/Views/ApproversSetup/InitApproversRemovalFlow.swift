//
//  InitApproversRemovalFlow.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI
import Moya
import Sentry

struct InitApproversRemovalFlow: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case creatingPolicySetup
        case replacingPolicy
        case done
    }
    
    @State private var step: Step = .creatingPolicySetup
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            switch (step) {
            case .creatingPolicySetup:
                ProgressView()
                    .onAppear {
                        createPolicySetupWithoutExternalApprovers()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .alert("Error", isPresented: $showingError, presenting: error) { _ in
                        Button {
                            dismiss()
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
                        cleanupAndDismiss()
                    },
                    intent: .removeApprovers
                )
            case .done:
                ApproversSetupDone(text: "Approvers removed")
                    .onAppear(perform: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            dismiss()
                        }
                    })
            }
        }
    }
    
    private func createPolicySetupWithoutExternalApprovers() {
        self.step = .creatingPolicySetup
        let ownerParticipantId = ParticipantId.random()
        let setupPolicyRequest = API.SetupPolicyApiRequest(
            threshold: 1,
            approvers: [
                .ownerAsApprover(API.ApproverSetup.OwnerAsApprover(
                    participantId: ownerParticipantId,
                    label: "Me"
                ))
            ]
        )
        
        apiProvider.decodableRequest(
            with: session,
            endpoint: .setupPolicy(setupPolicyRequest)
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                self.step = .replacingPolicy
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func cleanupAndDismiss() {
        dismiss()
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

