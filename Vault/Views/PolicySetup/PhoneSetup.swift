//
//  PhoneSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-18.
//

import SwiftUI
import Moya

struct PhoneSetup: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var phone: String = ""
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
        self._phone = State(initialValue: user.phoneContact?.value ?? "")
    }

    var body: some View {
        VStack(alignment: .leading) {
            BackButtonBar(caption: "Name", action: onBack)

            Spacer()

            HStack {
                Text("We will also need your phone number:")
                    .font(.title2)
                Spacer()
            }

            TextField("Type here", text: $phone)
                .font(.title)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)

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
            .disabled(phone.isEmpty || inProgress)

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

        apiProvider.decodableRequest(.createUser(contactType: .phone, value: phone)) { (result: Result<API.CreateUserApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                // response.verificationId needs to be sent back
                onSuccess()
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
struct PhoneSetup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PhoneSetup(user: .sample, onBack: {}, onSuccess: { })
        }
    }
}
#endif
