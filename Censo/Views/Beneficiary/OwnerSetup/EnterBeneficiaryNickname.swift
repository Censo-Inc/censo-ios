//
//  EnterBeneficiaryNickname.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import Foundation
import SwiftUI
import Sentry

struct EnterBeneficiaryNickname: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var policy: API.Policy
    
    @StateObject private var nickname = BeneficiaryNickname()
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            Text("Give your beneficiary a nickname to identify them.")
                .font(.headline)
                .fontWeight(.regular)
                .padding(.bottom)

            VStack(spacing: 0) {
                TextField(text: $nickname.value) {
                    Text("Enter a nickname...")
                }
                .textFieldStyle(RoundedTextFieldStyle())
                .font(.headline)
                .frame(maxWidth: .infinity)
                
                Text(nickname.isTooLong ? "Can't be longer than \(nickname.limit) characters" : " ")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.red)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom)
            
            Button {
                submit()
            } label: {
                Group {
                    if submitting {
                        ProgressView()
                    } else {
                        Text("Continue")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .disabled(submitting || !nickname.isValid)
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
        .padding([.leading, .trailing], 32)
        .navigationInlineTitle("Add beneficiary")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(icon: .close)
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.submitting = false
        self.error = error
        self.showingError = true
    }
    
    private func submit() {
        self.submitting = true
            
        do {
            ownerRepository.inviteBeneficiary(
                API.InviteBeneficiaryApiRequest(
                    label: nickname.value,
                    deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: ownerRepository.deviceKey)
                )
            ) { result in
                switch result {
                case .success(let response):
                    ownerStateStoreController.replace(response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            SentrySDK.captureWithTag(error: error, tagValue: "Setup beneficiary")
            showError(CensoError.failedToSaveBeneficiaryName)
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            EnterBeneficiaryNickname(policy: .sample2Approvers)
        }
    }
}
#endif
