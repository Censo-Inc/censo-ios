//
//  Verification.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-17.
//

import SwiftUI
import Moya

struct Verification: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var token = ""
    @State private var currentAlert: AlertType?
    @State private var isVerifying = false

    enum AlertType {
        case submitError(Error)
        case verificationError(Error)
    }

    var contact: API.Contact
    var onBack: () -> Void
    var onSuccess: () -> Void

    var canVerify: Bool {
        !token.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            BackButtonBar(caption: contact.contactType == .email ? "Email" : "Phone", action: onBack)
                .padding()

            Spacer()

            HStack {
                (Text("A verification code has been sent to \n") + Text(contact.value).font(.title2))
                    .padding()
                Spacer()
            }


            Spacer().frame(height: 50)

            TextField(text: $token, label: {
                Text("Type code here")
            })
            .onSubmit {
                if canVerify { submit() }
            }
            .font(.title)
            .keyboardType(.numberPad)
            .foregroundColor(Color.black)
            .accentColor(Color.Censo.red)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .disabled(isVerifying)
            .padding()
            .textContentType(.oneTimeCode)

            Spacer()

            Button {
                sendVerification()
            } label: {
                Text("Resend Verification Code")
                    .foregroundColor(.Censo.red)
            }
            .disabled(isVerifying)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .padding()

            Button(action: submit) {
                Group {
                    if isVerifying {
                        ProgressView()
                    } else {
                        Text("Submit")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledButtonStyle())
            .disabled(!canVerify || isVerifying)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .padding()
        }
        .foregroundColor(.Censo.primaryForeground)
        .alert(item: $currentAlert) { item in
            switch item {
            case .verificationError:
                return Alert(
                    title: Text("Verification Error"),
                    message: Text("An error occured trying to send your verification code"),
                    dismissButton: .cancel(Text("Try Again"))
                )
            case .submitError(let error):
                return Alert(
                    title: Text("Token Error"),
                    message: Text(error.localizedDescription),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
        .preferredColorScheme(.light)
    }

    private func sendVerification() {
        isVerifying = true

        apiProvider.request(.createUser(contactType: contact.contactType, value: contact.value)) { result in
            isVerifying = false

            switch result {
            case .success(let response) where response.statusCode <= 400:
                break
            case .success(let response):
                currentAlert = .verificationError(MoyaError.statusCode(response))
            case .failure(let error):
                currentAlert = .verificationError(error)
            }
        }
    }

    private func submit() {
        isVerifying = true

        apiProvider.request(.contactVerification(verificationId: "", code: token)) { result in
            switch result {
            case .success(let response) where response.statusCode <= 400:
                onSuccess()
            case .success(let response):
                isVerifying = false
                currentAlert = .submitError(MoyaError.statusCode(response))
            case .failure(let error):
                isVerifying = false
                currentAlert = .submitError(error)
            }
        }
    }
}

extension Verification.AlertType: Identifiable {
    var id: Int {
        switch self {
        case .submitError:
            return 0
        case .verificationError:
            return 1
        }
    }
}

#if DEBUG
struct Verification_Previews: PreviewProvider {
    static var previews: some View {
        Verification(contact: .sample, onBack: {}, onSuccess: {})
    }
}

extension API.Contact {
    static var sample: Self {
        .init(identifier: "1234567879", contactType: .email, value: "david@talknigheads.com", verified: false)
    }
}
#endif
