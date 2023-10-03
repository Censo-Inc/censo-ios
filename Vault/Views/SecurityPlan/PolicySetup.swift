//
//  PolicySetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-29.
//

import SwiftUI

struct PolicySetup: View {
    @Environment(\.dismiss) var dismiss

    @State private var newOwnerState: API.OwnerState?

    var session: Session
    var threshold: Int
    var approvers: [String]
    var onComplete: (API.OwnerState) -> Void

    private var guardians: Result<[API.GuardianSetup], Error> {
        do {
            return .success(try approvers.map { label in
                .externalApprover(
                    API.GuardianSetup.ExternalApprover(
                        participantId: .random(),
                        label: label,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    ))
                }
            )
        } catch {
            return .failure(error)
        }
    }

    var body: some View {
        Group {
            if let newOwnerState = newOwnerState {
                IdentityEstablished {
                    onComplete(newOwnerState)
                }
                .navigationBarHidden(true)
            } else {
                switch guardians {
                case .success(let guardians):
                    InitialIdentityVerification(
                        threshold: threshold,
                        guardians: guardians,
                        session: session
                    ) { ownerState in
                        newOwnerState = ownerState
                    }
                case .failure(let error):
                    Text("Eror creating secret: \(error.localizedDescription)")
                }
            }
        }
        .navigationTitle(Text("Setup Security Plan"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .font(.body.bold())
                }
            }
        }
    }
}

#if DEBUG
struct PolicySetup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PolicySetup(session: .sample, threshold: 2, approvers: ["Jerry", "Elaine"]) { _ in }
        }
    }
}

extension Session {
    static var sample: Self {
        .init(deviceKey: .sample, userCredentials: .sample)
    }
}

extension UserCredentials {
    static var sample: Self {
        .init(idToken: Data(), userIdentifier: "userIdentifier")
    }
}
#endif
