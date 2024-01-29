//
//  AuthenticationReset.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.01.24.
//

import Foundation
import SwiftUI
import Moya

struct AuthenticationReset: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    var onExit: () -> Void
    
    @State private var confirmExit = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        let resetType = ownerState.authType == .facetec ? "Biometry" : "Password"
        Group {
            switch (ownerState.authenticationReset) {
            case nil:
                ProgressView()
                    .onAppear {
                        requestAuthenticationReset()
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
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                confirmExit = true
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    })
            case .anotherDevice:
                PendingAuthResetOnAnotherDevice(
                    authType: ownerState.authType,
                    onCancelReset: {
                        confirmExit = true
                    }
                )
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            confirmExit = true
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                })
            case .thisDevice(let reset):
                switch (reset.status) {
                case .requested:
                    PendingAuthResetOnThisDevice(
                        session: session,
                        authType: ownerState.authType,
                        policy: ownerState.policy,
                        authReset: reset,
                        onCancel: {
                            confirmExit = true
                        },
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                case .approved:
                    ReplaceAuthentication(
                        session: session,
                        authType: ownerState.authType == .facetec ? .facetec : .password,
                        onComplete: { ownerState in
                            onOwnerStateUpdated(ownerState)
                            onExit()
                        },
                        onCancel: {
                            confirmExit = true
                        }
                    )
                }
            }
        }
        .alert("Are you sure?", isPresented: $confirmExit) {
            Button {
                cancelAuthenticationResetAndExit()
            } label: { Text("Confirm") }
            Button {
            } label: { Text("Cancel") }
        } message: {
            Text("\(resetType) reset will be cancelled and your progress will be lost.")
        }
        .navigationTitle("\(resetType) Reset")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private func requestAuthenticationReset() {
        apiProvider.decodableRequest(with: session, endpoint: .requestAuthenticationReset) { (result: Result<API.InitiateAuthenticationResetApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func cancelAuthenticationReset(onSuccess: @escaping () -> Void = {}) {
        apiProvider.decodableRequest(with: session, endpoint: .cancelAuthenticationReset) { (result: Result<API.CancelAuthenticationResetApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                onSuccess()
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func cancelAuthenticationResetAndExit() {
        cancelAuthenticationReset(onSuccess: {
            onExit()
        })
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}
