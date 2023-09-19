//
//  EmailSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-17.
//

import SwiftUI
import CryptoKit
import Moya

struct SignIn: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var value: String = ""
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var onSuccess: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            Text("    Login in with your Apple Id")

            Spacer()
                .frame(maxHeight: 60)


            TextField("Type Apple Id here", text: $value)
                .font(.title)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)

            Spacer()

            Button {
                createUser()
            } label: {
                Group {
                    if inProgress {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(value.isEmpty || inProgress)

            .buttonStyle(FilledButtonStyle())
        }
        .padding()
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

    private func createUser() {
        inProgress = true

        apiProvider.request(.signIn(identityToken: Data(SHA256.hash(data: value.data(using: .utf8)!)).toHexString(), jwtToken: "")) { result in
            switch result {
            case .success(let response) where response.statusCode < 400:
                onSuccess()
            case .success(let response):
                showError(MoyaError.statusCode(response))
            case .failure(let error):
                showError(error)
            }
        }
    }
}

struct BackButtonBar: View {
    var caption: String
    var action: () -> Void

    var body: some View {
        HStack {
            Button {
                action()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18).weight(.heavy))

                    Text(caption)
                        .font(.system(size: 16).weight(.bold))
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
    }
}


#if DEBUG
struct SignIn_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignIn(onSuccess: {})
        }
    }
}
#endif
