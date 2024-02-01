//
//  PasswordAuth.swift
//  Censo
//
//  Created by Ben Holzman on 11/15/23.
//

import SwiftUI
import Moya

struct PasswordAuth<ResponseType : Decodable>: View {
    var submit: (API.Authentication.Password, @escaping (Result<ResponseType, MoyaError>) -> Void) -> Void
    var onSuccess: (ResponseType) -> Void
    var onInvalidPassword: (() -> Void)?
    var onAuthResetTriggered: (() -> Void)?

    @State private var password = ""
    @State private var invalidPassword = false
    @State private var disableContinue = false
    
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("Enter your password")
                .font(.title2.bold())
                .padding()

            SecureField("Enter your password...", text: $password) {
                doSubmit()
            }
            .textFieldStyle(RoundedTextFieldStyle())
            .padding()

            if invalidPassword {
                Text("Password was invalid")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                
                if let onAuthResetTriggered = onAuthResetTriggered {
                    VStack(alignment: .center) {
                        Text("Having trouble with password verification?")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        Button(action: {
                            onAuthResetTriggered()
                        }, label: {
                            Text("Tap here.")
                                .font(.subheadline)
                                .bold()
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                        })
                    }
                }
            }

            Divider()

            Button {
                doSubmit()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            .disabled(disableContinue)
        }
        .padding()
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
    }
    
    private func doSubmit() {
        disableContinue = true
        
        if let cryptedPassword = pbkdf2(password: password) {
            submit(
                API.Authentication.Password(cryptedPassword: Base64EncodedString(data: cryptedPassword))
            ) { result in
                switch result {
                case .failure(MoyaError.underlying(CensoError.validation("Incorrect password"), _)):
                    invalidPassword = true
                    disableContinue = false
                    if let onInvalidPassword = onInvalidPassword {
                        onInvalidPassword()
                    }
                case .failure(let error):
                    self.error = error
                    self.showingError = true
                    disableContinue = false
                case .success(let response):
                    onSuccess(response)
                }
            }
        } else {
            disableContinue = false
        }
    }
}

#if DEBUG
#Preview {
    PasswordAuth<API.UnlockWithPasswordApiResponse>(
        submit: { _, _ in },
        onSuccess: { _ in }
    )
}
#endif
