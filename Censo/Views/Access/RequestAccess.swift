//
//  RequestAccess.swift
//  Censo
//
//  Created by Brendan Flood on 10/25/23.
//

import SwiftUI
import Moya

struct AccessAvailableViewParams {
    var onFinished: () -> Void
}

struct RequestAccess<AccessAvailableView>: View where AccessAvailableView : View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    var intent: API.Access.Intent
    
    @ViewBuilder var accessAvailableView: (AccessAvailableViewParams) -> AccessAvailableView
    
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        switch (ownerState.access) {
        case nil:
            ProgressView()
                .onAppear {
                    requestAccess()
                }
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
        case .anotherDevice:
            AccessOnAnotherDevice(
                onCancelAccess: deleteAccessAndDismiss
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        case .thisDevice(let access):
            // delete it in case this is a leftover access with other intent
            if access.intent != intent {
                ProgressView()
                    .onAppear {
                        deleteAccess()
                    }
            } else {
                switch (access.status) {
                case .requested:
                    AccessApproval(
                        access: access,
                        policy: ownerState.policy,
                        onCancel: {
                            deleteAccess(onSuccess: { dismiss() })
                        }
                    )
                case .timelocked:
                    ProgressView()
                        .onAppear {
                            dismiss()
                        }
                case .available:
                    accessAvailableView(AccessAvailableViewParams(
                        onFinished: deleteAccessAndDismiss
                    ))
                }
            }
        }
    }
    
    private func requestAccess() {
        ownerRepository.requestAccess(API.RequestAccessApiRequest(intent: intent), { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure(let error):
                showError(error)
            }
        })
    }
    
    private func deleteAccessAndDismiss() {
        deleteAccess(onSuccess: {
            dismiss()
        })
    }
    
    private func deleteAccess(onSuccess: @escaping () -> Void = {}) {
        ownerRepository.deleteAccess { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
                onSuccess()
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func refreshState() {
        ownerStateStoreController.reload()
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}


#if DEBUG
#Preview {
    let policy = API.Policy.sample2Approvers
    
    return NavigationView {
        LoggedInOwnerPreviewContainer {
            RequestAccess(
                ownerState: API.OwnerState.Ready(
                    policy: policy,
                    vault: .sample,
                    access: .thisDevice(API.Access.ThisDevice(
                        guid: "",
                        status: API.Access.Status.requested,
                        createdAt: Date(),
                        unlocksAt: Date(),
                        expiresAt: Date(),
                        approvals: policy.approvers.map({
                            API.Access.ThisDevice.Approval(
                                participantId: $0.participantId,
                                approvalId: "",
                                status: .initial
                            )
                        }),
                        intent: .accessPhrases
                    )),
                    authType: .facetec,
                    subscriptionStatus: .active,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: false
                ),
                intent: .accessPhrases,
                accessAvailableView: { _ in
                    Text("Access available")
                }
            )
        }
    }
}
#endif
