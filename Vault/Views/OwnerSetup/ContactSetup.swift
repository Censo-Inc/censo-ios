//
//  EmailSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-17.
//

import SwiftUI
import Moya

struct ContactSetup: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var contactType: API.Contact.ContactType = .email
    @State private var value: String = ""
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var onSuccess: (PendingContactVerification) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            Text("    We need to collect and verify your contact information in the event you need to recover your secret")

            Spacer()
                .frame(maxHeight: 60)

            HStack {
                Text("Contact method:")
                    .font(.title2)
                Spacer()

                Picker("Contact Method", selection: $contactType) {
                    Text("Email").tag(API.Contact.ContactType.email)
                    Text("SMS").tag(API.Contact.ContactType.phone)
                }
                .tint(.Censo.red)
            }

            TextField("Type here", text: $value)
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
                        Text("Verify")
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

        apiProvider.decodableRequest(.createUser(contactType: contactType, value: value)) { (result: Result<API.CreateUserApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onSuccess(PendingContactVerification(contactType: .email, contactValue: value, verificationId: response.verificationId))
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
            ContactSetup(onSuccess: { _ in })
        }
    }
}
#endif
