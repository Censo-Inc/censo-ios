//
//  Login.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI
import AuthenticationServices

struct Login: View {
    var onSuccess: () -> Void

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
                            Keychain.userIdentifier = appleIDCredential.user
                            onSuccess()
                        } else {
                            break
                        }
                    case .failure(let error):
                        print("Authorisation failed: \(error.localizedDescription)")
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .padding()
        }
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login() {}
    }
}
#endif
