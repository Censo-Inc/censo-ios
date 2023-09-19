//
//  Login.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI
import AuthenticationServices

struct Login: View {
    @State private var showingError = false
    @State private var error: Error?

    var onSuccess: () -> Void

    enum AppleSignInError: Error {
        case noIdentityToken
    }

    var body: some View {
        VStack {
            Image("LogoColor")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(60)

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                switch result {
                    case .success(let authResults):
                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                            guard let idToken = appleIDCredential.identityToken else {
                                showError(AppleSignInError.noIdentityToken)
                                break
                            }

                            Keychain.userCredentials = .init(idToken: idToken, userIdentifier: appleIDCredential.user)
                            onSuccess()
                        } else {
                            break
                        }
                    case .failure(let error):
                        showError(error)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .padding()
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button(role: .cancel, action: {}) {
                Text("OK")
            }
        } message: { error in
            Text("There was an error trying to sign you in: \(error.localizedDescription)")
        }
    }

    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login() {}
    }
}
#endif
