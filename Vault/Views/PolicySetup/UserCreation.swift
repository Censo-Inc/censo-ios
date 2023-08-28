//
//  UserCreation.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-16.
//

import SwiftUI
import Moya

struct UserCreation: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var name: String = ""
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var user: API.User
    var onSuccess: () -> Void

    init(user: API.User, onSuccess: @escaping () -> Void) {
        self.user = user
        self.onSuccess = onSuccess
        self._name = State(wrappedValue: user.name)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            Text("Lets start with your name...")
                .font(.largeTitle)

            Text("This is used to identify you to your guardians")
                .padding(.vertical)

            TextField("Enter your full name here", text: $name)
                .font(.title)

            Spacer()

            Button {
                createUser()
            } label: {
                Group {
                    if inProgress {
                        ProgressView()
                    } else {
                        Text("Next")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(name.isEmpty)
        }
        .padding()
        .buttonStyle(FilledButtonStyle())
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

        apiProvider.request(.createDevice) { result in
            switch result {
            case .success(let response) where response.statusCode <= 400:
                apiProvider.request(.createUser(name: name)) { result in
                    switch result {
                    case .success(let response) where response.statusCode <= 400:
                        onSuccess()
                    case .success(let response):
                        showError(MoyaError.statusCode(response))
                    case .failure(let error):
                        showError(error)
                    }
                }
            case .success(let response):
                showError(MoyaError.statusCode(response))
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
struct UserCreation_PreviewProvider: PreviewProvider {
    static var previews: some View {
        UserCreation(user: .empty) { }
    }
}
#endif
