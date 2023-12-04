//
//  RequestAccess.swift
//  Censo
//
//  Created by Brendan Flood on 10/25/23.
//

import SwiftUI
import Moya
import raygun4apple

struct AccessAvailableViewParams {
    var onFinished: () -> Void
}

struct RequestAccess<AccessAvailableView>: View where AccessAvailableView : View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    var intent: API.Recovery.Intent
    
    @ViewBuilder var accessAvailableView: (AccessAvailableViewParams) -> AccessAvailableView
    
    @State private var deletingRecovery = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        if deletingRecovery {
            ProgressView()
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        refreshState()
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
        } else {
            switch (ownerState.recovery) {
            case nil:
                ProgressView()
                    .onAppear {
                        requestRecovery()
                    }
                    .alert("Error", isPresented: $showingError, presenting: error) { _ in
                        Button {
                            dismiss()
                        } label: {
                            Text("OK")
                        }
                    }
            case .anotherDevice:
                AccessOnAnotherDevice(
                    onCancelAccess: deleteRecoveryAndDismiss
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                    }
                })
            case .thisDevice(let recovery):
                // delete it in case this is a leftover recovery with other intent
                if recovery.intent != intent {
                    ProgressView()
                        .onAppear {
                            deleteRecovery()
                        }
                } else {
                    switch (recovery.status) {
                    case .requested:
                        AccessApproval(
                            session: session,
                            policy: ownerState.policy,
                            recovery: recovery,
                            onCancel: {
                                deleteRecovery(onSuccess: { dismiss() })
                            },
                            onOwnerStateUpdated: onOwnerStateUpdated
                        )
                    case .timelocked:
                        Text("Timelocked")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar(content: {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        dismiss()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .foregroundColor(.black)
                                    }
                                }
                            })
                    case .available:
                        accessAvailableView(AccessAvailableViewParams(
                            onFinished: deleteRecoveryAndDismiss
                        ))
                    }
                }
            }
        }
    }
    
    private func requestRecovery() {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .requestRecovery(API.RequestRecoveryApiRequest(intent: intent))
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func deleteRecoveryAndDismiss() {
        deleteRecovery(onSuccess: {
            dismiss()
        })
    }
    
    private func deleteRecovery(onSuccess: @escaping () -> Void = {}) {
        self.deletingRecovery = true
        apiProvider.decodableRequest(with: session, endpoint: .deleteRecovery) { (result: Result<API.DeleteRecoveryApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                onSuccess()
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }
    
    private func refreshState() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdated(user.ownerState)
            default:
                break
            }
        }
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
        RequestAccess(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: policy,
                vault: .sample,
                recovery: .thisDevice(API.Recovery.ThisDevice(
                    guid: "",
                    status: API.Recovery.Status.requested,
                    createdAt: Date(),
                    unlocksAt: Date(),
                    expiresAt: Date(),
                    approvals: policy.guardians.map({
                        API.Recovery.ThisDevice.Approval(
                            participantId: $0.participantId,
                            approvalId: "",
                            status: .initial
                        )
                    }),
                    intent: .accessPhrases
                )),
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in },
            intent: .accessPhrases,
            accessAvailableView: { _ in
                Text("Access available")
            }
        )
    }
}
#endif
