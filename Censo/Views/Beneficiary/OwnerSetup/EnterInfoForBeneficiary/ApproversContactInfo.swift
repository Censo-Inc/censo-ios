//
//  ApproversContactInfo.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI
import Sentry

extension EnterInfoForBeneficiary {
    struct ApproversContactInfo: View {
        @Environment(\.dismiss) var dismiss
        @EnvironmentObject var ownerRepository: OwnerRepository
        @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
        
        var policy: API.Policy
        var publicMasterEncryptionKey: Base58EncodedPublicKey
        
        @State private var contactInfos: [ApproverContactInfo] = []
        @State private var error: Error?
        @State private var showErrorAlert = false
        @State private var submitInProgress = false
        
        struct ApproverContactInfo {
            var participantId: ParticipantId
            var label: String
            var contactInfo: String
        }
        
        var body: some View {
            VStack(spacing: 0) {
                if let error = error, !showErrorAlert {
                    RetryView(error: error, action: decrypt)
                } else if contactInfos.isEmpty {
                    ProgressView()
                        .onAppear(perform: decrypt)
                } else {
                    List {
                        ForEach(0 ..< contactInfos.count, id: \.self) { index in
                            VStack(alignment: .center, spacing: 0) {
                                Text(contactInfos[index].label)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.bottom)
                                
                                TextField("Enter contact information", text: $contactInfos[index].contactInfo, axis: .vertical)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .disabled(submitInProgress)
                                    .padding()
                                    .lineLimit(4, reservesSpace: true)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                            .foregroundColor(.Censo.gray224)
                                    )
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.horizontal, 32)
                            .padding(.bottom)
                        }
                        
                        Button {
                            submit()
                        } label: {
                            Text("Save information")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .disabled(submitInProgress)
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, 32)
                        .padding(.vertical)
                        .listRowInsets(EdgeInsets())
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .padding(.vertical)
            .alert("Error", isPresented: $showErrorAlert, presenting: error) { _ in
                Button {
                    self.error = nil
                } label: { Text("OK") }
            } message: { error in
                Text("Failed to save phrase.\n\(error.localizedDescription)")
            }
            .navigationInlineTitle("Legacy - Approver information")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            }
        }
        
        private func decrypt() {
            do {
                self.contactInfos = try policy.externalApprovers.map({ approver in
                    let encryptedContactInfo = policy.beneficiary?.contactInfo(forParticipantId: approver.participantId)?.encryptedContactInfo
                    
                    return ApproverContactInfo(
                        participantId: approver.participantId,
                        label: approver.label,
                        contactInfo: try encryptedContactInfo.map({
                            try ownerRepository.decryptStringWithApproverKey(data: $0, policy: policy)
                        }) ?? ""
                    )
                })
            } catch {
                SentrySDK.captureWithTag(error: error, tagValue: "Approver contact info editing")
                self.error = CensoError.failedToDecryptApproverContactInfo
            }
        }
        
        private func submit() {
            do {
                submitInProgress = true
                
                let encryptedContactInfos: [API.UpdateBeneficiaryApproverContactInfoApiRequest.ApproverContactInfo] = try contactInfos.map({
                    let contactInfoData = $0.contactInfo.data(using: .utf8)!
                    return API.UpdateBeneficiaryApproverContactInfoApiRequest.ApproverContactInfo(
                        participantId: $0.participantId,
                        beneficiaryKeyEncryptedInfo: try policy.beneficiary!.beneficiaryKeyInfo!.publicKey.toEncryptionKey().encrypt(data: contactInfoData),
                        ownerApproverKeyEncryptedInfo: try ownerRepository.encryptWithApproverPublicKey(data: contactInfoData, policy: policy),
                        masterKeyEncryptedInfo: try publicMasterEncryptionKey.toEncryptionKey().encrypt(data: contactInfoData)
                    )
                })
                
                ownerRepository.updateApproversContactInfo(encryptedContactInfos, { result in
                    submitInProgress = false
                    
                    switch result {
                    case .success(let payload):
                        ownerStateStoreController.replace(payload.ownerState)
                        dismiss()
                    case .failure(let error):
                        self.error = error
                        self.showErrorAlert = true
                    }
                })
            } catch {
                submitInProgress = false
                
                SentrySDK.captureWithTag(error: error, tagValue: "Approver contact info editing")
                self.error = CensoError.failedToEncryptApproverContactInfo
                self.showErrorAlert = true
            }
        }
    }
}
