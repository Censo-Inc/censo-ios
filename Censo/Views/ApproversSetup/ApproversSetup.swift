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
        case intro
        case setupPrimary
        case setupAlternate
        case replacingPolicy
        case done
        
        static func fromOwnerState(_ ownerState: API.OwnerState.Ready) -> Step {
            if ownerState.policySetup?.alternateApprover == nil {
                if ownerState.policySetup?.primaryApprover?.isConfirmed == true {
                    return .setupAlternate
                } else {
                    return .setupPrimary
                }
            } else {
                if ownerState.policySetup?.alternateApprover?.isConfirmed == true {
                    return .replacingPolicy
                } else {
                    return .setupAlternate
                }
            }
        }
    }
    
    @State private var step: Step
    @State private var showingError = false
    @State private var error: Error?
    @State private var showDeletePolicySetupConfirmation = false
    @State private var deletingPolicySetup = false
    
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
        self._step = State(initialValue: .intro)
    }
    
    var body: some View {
        if deletingPolicySetup {
            ProgressView()
        } else {
            switch (step) {
            case .intro:
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            Text("Increase your security")
                                .font(.title2)
                                .bold()
                                .padding(.vertical)
                            
                            Text("""
                            Adding two trusted approvers increases your security by eliminating any single point of compromise while providing extra backup should you or your approvers lose your credentials.
                            
                            Choose approvers who you think are reliable and you can trust.
                            
                            While they can never access your seed phrase (only you can), you will need at least one of the two you choose to help you access it.
                            """
                            )
                            .font(.subheadline)
                            .padding(.vertical)
                            .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Button {
                                self.step = Step.fromOwnerState(ownerState)
                            } label: {
                                HStack {
                                    Spacer()
                                    Image("TwoPeopleWhite")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    Text(ownerState.policySetup == nil ? "Add approvers" : "Resume adding approvers")
                                        .font(.title3)
                                        .fixedSize(horizontal: true, vertical: false)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(RoundedButtonStyle())
                            .padding(.top)
                            
                            if ownerState.policySetup != nil {
                                Button {
                                    showDeletePolicySetupConfirmation = true
                                } label: {
                                    Text("Cancel")
                                        .font(.title3)
                                        .tint(Color.Censo.darkBlue)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.top)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .padding([.leading, .trailing], 32)
                        .frame(minHeight: geometry.size.height)
                    }
                }
                .alert("Are you sure?", isPresented: $showDeletePolicySetupConfirmation) {
                    Button {
                        deletePolicySetup()
                    } label: { Text("Confirm") }
                    Button {
                    } label: { Text("Cancel") }
                } message: {
                    Text("Approvers activation progress made so far will be lost.")
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
            case .setupPrimary:
                SetupApprover(
                    session: session,
                    policySetup: ownerState.policySetup,
                    isPrimary: true,
                    onComplete: {
                        step = .setupAlternate
                    },
                    onOwnerStateUpdated: onOwnerStateUpdated,
                    onBack: {
                        step = .intro
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
                    onOwnerStateUpdated: onOwnerStateUpdated
                )
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
                Activated(
                    policy: ownerState.policy
                )
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        dismiss()
                    }
                })
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        dismiss()
                    }
                })
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    private func deletePolicySetup() {
        deletingPolicySetup = true
        apiProvider.decodableRequest(
            with: session,
            endpoint: .deletePolicySetup
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            deletingPolicySetup = false
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                dismiss()
            case .failure(let error):
                showError(error)
            }
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
                policySetup: policySetup,
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
