//
//  InitialIdentityVerification.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-29.
//

import SwiftUI
import Moya

struct InitialIdentityVerification: View {
    @Environment(\.apiProvider) var apiProvider
    var threshold: Int
    var guardians: [API.GuardianSetup]
    var session: Session
    var onSuccess: (API.OwnerState) -> Void

    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var body: some View {
        if inProgress {
            ProgressView()
        } else {
            VStack {
                Text("Establish your identity")
                    .font(.title.bold())
                    .padding()

                InfoBoard {
                    Text("""
                    Access to your seed phrases always requires your approval which is obtained using an encrypted 3d face scan to confirm your identity.

                     This scan is not associated with any personally identifiable information and it provides a reliable way to securely control access to your seed phrases
                    """
                    )
                    .font(.callout)
                }

                Spacer()

                Button {
                } label: {
                    Text("How does this work?")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
                .padding(.horizontal)
                .buttonStyle(BorderedButtonStyle())

                Button {
                    setupPolicy()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
                .padding()
                .buttonStyle(FilledButtonStyle())
            }
            .multilineTextAlignment(.center)
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                    showingError = false
                    error = nil
                } label: {
                    Text("OK")
                }
            } message: { error in
                Text("There was an error submitting your info.\n\(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false

        self.error = error
        self.showingError = true
    }
    
    private func setupPolicy() {
        self.inProgress = true
        apiProvider.decodableRequest(
            with: session,
            endpoint: .setupPolicy(API.SetupPolicyApiRequest( threshold: threshold, guardians: guardians))
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onSuccess(response.ownerState)
                self.inProgress = false
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
struct IdentityVerification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InitialIdentityVerification(threshold: 1, guardians: [.sample, .sample2], session: .sample) { _ in

            }
        }
    }
}

extension Base64EncodedString {
    static var sample: Self {
        try! .init(value: "")
    }
}

extension API.GuardianSetup {
    static var sample: Self {
        .externalApprover(ExternalApprover(participantId: .random(), label: "Jerry", deviceEncryptedTotpSecret: .sample))
    }

    static var sample2: Self {
        .externalApprover(ExternalApprover(participantId: .random(), label: "Kramer", deviceEncryptedTotpSecret: .sample))
    }
}
#endif
