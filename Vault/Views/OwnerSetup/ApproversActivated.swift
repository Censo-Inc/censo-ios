//
//  ApproversActivated.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-05.
//

import SwiftUI
import Moya

struct ApproversActivated: View {
    @Environment(\.apiProvider) private var apiProvider

    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var session: Session
    var guardianSetup: API.OwnerState.GuardianSetup
    var onOwnerStateUpdate: (API.OwnerState) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Text("Approvers Activated!")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.Censo.darkBlue)

                    Spacer()

                    VStack(spacing: 8) {
                        ForEach(guardianSetup.guardians, id: \.participantId) { guardian in
                            ApproverActivationRow(
                                session: session,
                                prospectGuardian: guardian,
                                onOwnerStateUpdate: onOwnerStateUpdate
                            )
                        }
                    }

                    Button {
                        createPolicy()
                    } label: {
                        if inProgress {
                            ProgressView()
                        } else {
                            Text("Continue")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .frame(height: 44)
                        }
                    }
                    .buttonStyle(FilledButtonStyle())
                    .padding()
                    .disabled(inProgress)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
    }

    private func showError(_ error: Error) {
        inProgress = false

        self.error = error
        self.showingError = true
    }

    private func createPolicy() {
        let guardianProspects = guardianSetup.guardians

        var policySetupHelper: PolicySetupHelper
        var signatureByPreviousIntermediateKey: Base64EncodedString
        do {
            policySetupHelper = try PolicySetupHelper(
                threshold: guardianSetup.threshold,
                guardians: guardianProspects.map({($0.participantId, try getGuardianPublicKey(status: $0.status))})
            )
            signatureByPreviousIntermediateKey = try Base64EncodedString(value: "")
        } catch {
            showError(error)
            return
        }
        return apiProvider.decodableRequest(
            with: session,
            endpoint: .replacePolicy(
                API.ReplacePolicyApiRequest(
                    intermediatePublicKey: policySetupHelper.intermediatePublicKey,
                    guardianShards: policySetupHelper.guardians,
                    encryptedMasterPrivateKey: policySetupHelper.encryptedMasterPrivateKey,
                    masterEncryptionPublicKey: policySetupHelper.masterEncryptionPublicKey,
                    signatureByPreviousIntermediateKey: signatureByPreviousIntermediateKey
                )
            )
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdate(response.ownerState)
            case .failure(let error):
                showError(error)
            }
        }
    }

    private func getGuardianPublicKey(status: API.GuardianStatus) throws -> Base58EncodedPublicKey {
        switch(status) {
        case .confirmed(let confirmed):
            return confirmed.guardianPublicKey
        default:
            throw PolicySetupError.badPublicKey
        }
    }
}

#if DEBUG
struct ApproversActivated_Previews: PreviewProvider {
    static var previews: some View {
        OpenVault {
            ApproversActivated(session: .sample, guardianSetup: .sample, onOwnerStateUpdate: { _ in })
        }
    }
}
#endif
