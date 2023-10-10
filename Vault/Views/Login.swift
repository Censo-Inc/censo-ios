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
            Spacer()
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 124)

            Image("CensoText")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 208)
            
            Text("sensible crypto security")
                .font(.system(size: 24))
                .padding()
            
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
            .frame(maxWidth: 322, maxHeight: 64)
            .cornerRadius(100.0)
            .padding()
            HStack {
                Image(systemName: "info.circle")
                Text("Why Apple ID?")
            }
            Spacer()
            VStack {
                HStack(alignment: .top) {
                    VStack {
                        Image(systemName: "eye.slash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 25)
                        Text("No personal info required, ever")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Image(systemName: "lock.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 25)
                        Text("Multiple layers of authentication")
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                Divider()
                    .padding()
                HStack {
                    Link(destination: URL(string: "https://censo.co/terms/")!, label: {
                        Text("Terms")
                            .padding()
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .tint(.black)
                            .frame(width: .infinity)
                    })
                    Link(destination: URL(string: "https://censo.co/privacy/")!, label: {
                        Text("Privacy")
                            .padding()
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .tint(.black)
                            .frame(width: .infinity)
                    })
                    Link(destination: URL(string: "https://censo.co/support/")!, label: {
                        Text("Support")
                            .padding()
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .tint(.black)
                            .frame(width: .infinity)
                    })
                }
            }.frame(height: 180)
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
