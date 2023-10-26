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
    @AppStorage("acceptedTermsOfUseVersion") var acceptedTermsOfUseVersion: String = ""

    var onSuccess: () -> Void

    enum AppleSignInError: Error {
        case noIdentityToken
    }

    var body: some View {
        if (acceptedTermsOfUseVersion != "") {
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
                    .font(.system(size: 24, weight: .semibold))
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
                        .font(.system(size: 18, weight: .medium))
                }
                Spacer()
                VStack {
                    HStack(alignment: .top) {
                        VStack {
                            Image("EyeSlash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("No personal info required, ever.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        VStack {
                            Image("Safe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Text("Multiple layers of authentication.")
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
                                .fontWeight(.bold)
                                .tint(.black)
                                .frame(maxWidth: .infinity)
                        })
                        Link(destination: URL(string: "https://censo.co/privacy/")!, label: {
                            Text("Privacy")
                                .padding()
                                .fontWeight(.bold)
                                .tint(.black)
                                .frame(maxWidth: .infinity)
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
        } else {
            TermsOfUse(
                text: TermsOfUse.v0_1,
                onAccept: {
                    acceptedTermsOfUseVersion = "v0.1"
                }
            )
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
