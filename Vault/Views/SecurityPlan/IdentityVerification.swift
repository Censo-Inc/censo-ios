//
//  InitialIdentityVerification.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-29.
//

import SwiftUI

struct InitialIdentityVerification: View {
    var threshold: Int
    var guardians: [API.GuardianSetup]
    var session: Session
    var onSuccess: (API.OwnerState) -> Void

    @State private var showingBiometry = false

    var body: some View {
        if showingBiometry {
            FacetecAuth<API.CreatePolicyApiResponse>(session: session) { verificationId, facetecBiometry in
                    .setupPolicy(
                        API.SetupPolicyApiRequest(
                            threshold: threshold,
                            guardians: guardians,
                            biometryVerificationId: verificationId,
                            biometryData: facetecBiometry
                        )
                    )
            } onSuccess: { response in
                onSuccess(response.ownerState)
            }
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
                    showingBiometry = true
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
                .padding()
                .buttonStyle(FilledButtonStyle())
            }
            .multilineTextAlignment(.center)
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
