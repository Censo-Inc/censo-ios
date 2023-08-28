//
//  EmailSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-17.
//

import SwiftUI
import Moya

struct EmailSetup: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var email: String = ""
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var user: API.User
    var onBack: () -> Void
    var onSuccess: () -> Void

    init(user: API.User, onBack: @escaping () -> Void, onSuccess: @escaping () -> Void) {
        self.user = user
        self.onBack = onBack
        self.onSuccess = onSuccess
        self._email = State(wrappedValue: user.emailContact?.value ?? "")
    }

    var body: some View {
        VStack(alignment: .leading) {
            BackButtonBar(caption: "Name", action: onBack)

            Spacer()

            Text("\(user.name.split(separator: " ").first.flatMap(String.init) ?? user.name),")
                .font(.title)
                .padding()

            Text("    We need to collect and verify your contact information in the event you need to recover your secret")

            Spacer()
                .frame(maxHeight: 60)

            HStack {
                Text("Lets start with your email address:")
                    .font(.title2)
                Spacer()
            }

            TextField("Type here", text: $email)
                .font(.title)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)

            Spacer()

            Button {
                createContact()
            } label: {
                Group {
                    if inProgress {
                        ProgressView()
                    } else {
                        Text("Verify")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(email.isEmpty || inProgress)

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

    private func createContact() {
        inProgress = true

        apiProvider.request(.createContact(type: .email, value: email)) { result in
            switch result {
            case .success(let response) where response.statusCode <= 400:
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
struct EmailSetup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmailSetup(user: .sample, onBack: {}, onSuccess: { })
        }
    }
}

extension API.User {
    static var sample: Self {
        .init(name: "Scruffy", contacts: [])
    }
}
#endif
