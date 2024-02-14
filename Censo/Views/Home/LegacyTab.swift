//
//  LegacyTab.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import SwiftUI

struct LegacyTab: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingAddBeneficiary = false
    @State private var showCancelBeneficiaryConfirmation = false
    @State private var cancelBeneficiaryConfirmationText: String = ""
    @State private var deleteBeneficiaryInProgress = false
    @State private var showingEnterInfo = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                if let beneficiary = ownerState.policy.beneficiary {
                    if beneficiary.isActivated {
                        Text("Your beneficiary will be able to securely access your seed phrases in case of unforeseen circumstances.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        BeneficiaryPill(beneficiary: beneficiary)
                        
                        Spacer()
                        
                        Text("Your beneficiary may need additional information about your approvers and your seed phrases")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingEnterInfo = true
                        } label: {
                            Text("Provide information")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .disabled(deleteBeneficiaryInProgress)
                        
                        Button {
                            cancelBeneficiaryConfirmationText = "This will remove \(beneficiary.label) as your beneficiary."
                            showCancelBeneficiaryConfirmation = true
                        } label: {
                            Text("Remove beneficiary")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom)
                        .buttonStyle(RoundedButtonStyle())
                        .accessibilityIdentifier("removeBeneficiary")
                        .disabled(deleteBeneficiaryInProgress)
                    } else {
                        LegacyNotActivated(
                            hasNoExternalApprovers: ownerState.policy.externalApproversCount == 0,
                            buttonLabel: "Resume adding beneficiary",
                            beneficiary: beneficiary,
                            onAddBeneficiary: {
                                self.showingAddBeneficiary = true
                            }
                        )
                        Button {
                            cancelBeneficiaryConfirmationText = "Beneficiary setup progress made so far will be lost."
                            showCancelBeneficiaryConfirmation = true
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .tint(Color.Censo.darkBlue)
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(deleteBeneficiaryInProgress)
                        .padding(.bottom)
                    }
                } else {
                    LegacyNotActivated(
                        hasNoExternalApprovers: ownerState.policy.externalApproversCount == 0,
                        buttonLabel: "Add beneficiary",
                        onAddBeneficiary: {
                            self.showingAddBeneficiary = true
                        }
                    )
                    .padding(.bottom)
                }
            }
            .navigationBarBackButtonHidden()
            .navigationBarTitleDisplayMode(.inline)
            .padding(.vertical)
            .padding(.horizontal, 32)
            .sheet(isPresented: $showingAddBeneficiary, content: {
                SetupBeneficiary(policy: ownerState.policy)
            })
            .sheet(isPresented: $showingEnterInfo, content: {
                EnterInfoForBeneficiary(ownerState: ownerState)
                    .interactiveDismissDisabled()
            })
            .alert("Are you sure?", isPresented: $showCancelBeneficiaryConfirmation) {
                Button {
                    deleteBeneficiary()
                } label: { Text("Confirm") }
                Button {
                } label: { Text("Cancel") }
            } message: {
                Text(cancelBeneficiaryConfirmationText)
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                    showingError = false
                    error = nil
                } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    private func deleteBeneficiary() {
        deleteBeneficiaryInProgress = true
        ownerRepository.deleteBeneficiary() { result in
            deleteBeneficiaryInProgress = false
            switch result {
            case .success(let payload):
                ownerStateStoreController.replace(payload.ownerState)
            case .failure(let err):
                error = err
                showingError = true
            }
        }
    }
}

struct LegacyNotActivated: View {
    
    var hasNoExternalApprovers: Bool
    var buttonLabel: String
    var beneficiary: API.Policy.Beneficiary? = nil
    var onAddBeneficiary: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ensure your digital assets are protected for your loved ones by adding a beneficiary")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            
            Text("A beneficiary will be able to securely access your seed phrases in case of unforeseen circumstances")
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom)
            
            if let beneficiary {
                BeneficiaryPill(beneficiary: beneficiary)
            }
            
            Spacer()
            
            if hasNoExternalApprovers {
                Text("You must add approvers before you can add a beneficiary.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.red)
                    .padding(.top)
            }
            
            Button {
                onAddBeneficiary()
            } label: {
                Text(buttonLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top)
            .buttonStyle(RoundedButtonStyle())
            .disabled(hasNoExternalApprovers)
            .accessibilityIdentifier("addBeneficiary")
        }
    }
}

#if DEBUG
#Preview("activated") {
    LoggedInOwnerPreviewContainer {
        LegacyTab(
            ownerState: .sample2ApproversAndBeneficiary
        )
    }
}

#Preview("approvers") {
    LoggedInOwnerPreviewContainer {
        LegacyTab(
            ownerState: .sample2Approvers
        )
    }
}

#Preview("no approvers") {
    LoggedInOwnerPreviewContainer {
        LegacyTab(
            ownerState: .sample
        )
    }
}

#Preview("accepted") {
    LoggedInOwnerPreviewContainer {
        LegacyTab(
            ownerState: API.OwnerState.Ready(
                policy: .sample2ApproversAndAcceptedBeneficiary,
                vault: .sample,
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
#endif
