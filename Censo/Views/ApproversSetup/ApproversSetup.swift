//
//  ApproversSetup.swift
//  Censo
//
//  Created by Anton Onyshchenko on 19.10.23.
//

import Foundation
import SwiftUI

struct ApproversSetup: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
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

    init(ownerState: API.OwnerState.Ready, step: Step) {
        self.ownerState = ownerState
        self._step = State(initialValue: step)
    }
    
    init(ownerState: API.OwnerState.Ready) {
        self.ownerState = ownerState
        self._step = State(initialValue: .intro)
    }
    
    var body: some View {
        if deletingPolicySetup {
            ProgressView()
        } else {
            switch (step) {
            case .intro:
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        Text("Add approvers, increase your security")
                            .font(.title3)
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
                                    .font(.headline)
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
                                    .font(.headline)
                                    .tint(Color.Censo.darkBlue)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical)
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
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                    }
                    .padding([.leading, .trailing], 32)
                    .frame(minHeight: geometry.size.height)
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
                .navigationInlineTitle("Add approvers")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DismissButton(icon: .close)
                    }
                }
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
                    policySetup: ownerState.policySetup,
                    isPrimary: true,
                    onComplete: {
                        step = .setupAlternate
                    },
                    onBack: {
                        step = .intro
                    }
                )
            case .setupAlternate:
                SetupApprover(
                    policySetup: ownerState.policySetup,
                    isPrimary: false,
                    onComplete: {
                        step = .replacingPolicy
                    }
                )
            case .replacingPolicy:
                ReplacePolicy(
                    ownerState: ownerState,
                    onSuccess: {
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
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    private func deletePolicySetup() {
        deletingPolicySetup = true
        ownerRepository.deletePolicySetup { result in
            deletingPolicySetup = false
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
                dismiss()
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            ApproversSetup(
                ownerState: API.OwnerState.Ready(
                    policy: .sample,
                    vault: .sample,
                    policySetup: policySetup,
                    authType: .facetec,
                    subscriptionStatus: .active,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: false
                )
            )
        }
    }
}
#endif
