//
//  InitApproversRemovalFlow.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI
import Sentry

struct InitApproversRemovalFlow: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
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
                    ownerState: ownerState,
                    onSuccess: {
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
        
        ownerRepository.setupPolicy(setupPolicyRequest) { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
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

