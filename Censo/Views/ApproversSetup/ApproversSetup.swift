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
        switch (step) {
        case .intro:
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    Text("Increase your security")
                        .font(.title2)
                        .bold()
                        .padding(.vertical)
                    
                    Text("""
                            Securely splitting your seed phrase amongst two Trusted Approvers and you provides increased security through safety in numbers and extra backup should any of the three of you lose your credentials.
                            
                            Choose approvers who you think are reliable and you can trust.
                            
                            While they can never access your seed phrase (only you can), you will need at least one of the two you choose to help you access it.
                            """
                    )
                    .font(.subheadline)
                    .padding(.vertical)
                    .fixedSize(horizontal: false, vertical: true)
                    
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
                            Spacer()
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.top)
                    
                    Spacer(minLength: 0)
                }
                .padding([.leading, .trailing], 32)
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
            Activated()
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
