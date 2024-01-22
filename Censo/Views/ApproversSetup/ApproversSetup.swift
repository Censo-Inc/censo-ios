//
//  ApproversSetup.swift
//  Censo
//
//  Created by Anton Onyshchenko on 19.10.23.
//

import Foundation
import SwiftUI
import Moya

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
    @State private var showLearnMore = false

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
                            Text("Add Approvers, increase your security")
                                .font(.title)
                                .bold()
                                .padding(.vertical)
                            
                            Text("""
                            If you use approvers, you will need to add a total of two.

                            Once you add them, whenever you want to access your seed phrases, you will need to request the help of one of your two approvers.

                            Approvers can be removed by you after you add them.
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
                            
                            Button {
                                showLearnMore = true
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .tint(.black)

                                    Text("Learn more")
                                        .tint(.black)
                                }
                            }
                            .padding(.top)
                            .frame(maxWidth: .infinity)

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
                .sheet(isPresented: $showLearnMore) {
                    LearnMore(title: "Trusted Approvers & Safety in Numbers", showLearnMore: $showLearnMore) {
                        VStack {
                            Text("""
                                Censo's approach to securing your cryptographically secured seed phrases and user credentials is innovative yet intuitive. By encrypting the seed phrase on your device and then distributing cryptographically provable approval rights to Trusted Approvers using Shamir Secret Sharing, we ensure maximum security and resilience.
                                
                                **The role of Trusted Approvers**
                                Your Trusted Approvers are your safety net. They could be close family, friends, or even your attorney – people you trust implicitly. But here’s the catch: they can help you access your seed phrase, yet they can't access it themselves. They are your guardians, not gatekeepers.
                                
                                **Simple for them, Secure for you**
                                Trusted Approvers don’t need to be crypto gurus. If they can use a smartphone, they can be your rock-solid backup. And for them, it's as easy as accepting a request and following a few simple steps.
                                
                                **The Power of Redundancy and No Single Point of Failure**
                                Our 2-of-3 threshold ensures there's no single point of failure. If one Trusted Approver is unavailable or loses their credentials, you still have a backup. It's a seamless blend of security and convenience.
                                
                                **A Fail-Safe for Authentication Too**
                                In the rare event you lose access to your usual authentication methods (like your Apple or Google Login ID), your Trusted Approvers can step in. Think of it as a triple-layered safety net.
                                """)
                            .padding()
                        }
                    }
                }
            case .setupPrimary:
                SetupApprover(
                    session: session,
                    policySetup: ownerState.policySetup,
                    isPrimary: true,
                    ownerEntropy: ownerState.policy.ownerEntropy,
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
                    ownerEntropy: ownerState.policy.ownerEntropy,
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
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
