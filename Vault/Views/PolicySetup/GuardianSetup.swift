//
//  GuardianSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import SwiftUI
import Moya

struct GuardianSetup: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var loadingState: UserLoadingState = .idle
    @State private var transitionForward = true
    @State private var setupStep: SetupStep = .name
    @State private var inProgress = false

    enum UserLoadingState {
        case idle
        case success(API.User)
        case failure(Error)
    }

    enum SetupStep {
        case name
        case email
        case emailVerification(API.Contact)
        case phone
        case phoneVerification(API.Contact)
        case done

        var stepNumber: Int {
            switch self {
            case .name: return 0
            case .email: return 1
            case .emailVerification: return 2
            case .phone: return 3
            case .phoneVerification: return 4
            case .done: return 5
            }
        }
    }

    var body: some View {
        switch loadingState {
        case .idle:
            VStack {
                Spacer()

                Text("You have yet to setup guardians for your vault!")
                    .font(.largeTitle)

                Spacer()

                Button {
                    reload()
                } label: {
                    Group {
                        if inProgress {
                            ProgressView()
                        } else {
                            Text("Setup now")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(inProgress)
            }
            .padding()
            .buttonStyle(FilledButtonStyle())
            .transition(.backslide)
        case .success(let user):
            UserSetup(setupStep: setupStep, user: user) { [setupStep] user, step in
                transitionForward = step.stepNumber > setupStep.stepNumber

                withAnimation {
                    loadingState = .success(user)
                    self.setupStep = step
                }
            } onError: { error in
                loadingState = .failure(error)
            }
            .transition(transitionForward ? .backslide : .frontslide)
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }

    private func reload() {
        inProgress = true

        apiProvider.decodableRequest(.user) { (result: Result<API.User, MoyaError>) in
            inProgress = false

            switch result {
            case .success(let user):
                transitionForward = true

                withAnimation {
                    self.loadingState = .success(user)
                }
            case .failure(MoyaError.statusCode(let response)) where response.statusCode == 204:
                transitionForward = true

                withAnimation {
                    self.loadingState = .success(.empty)
                }
            case .failure(let error):
                self.loadingState = .failure(error)
            }
        }
    }
}

extension API.User {
    static var empty: Self {
        .init(name: "", contacts: [])
    }
}

extension AnyTransition {
    static var backslide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }

    static var frontslide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
    }
}

#if DEBUG
struct GuardianSetup_Previews: PreviewProvider {
    static var previews: some View {
        GuardianSetup()
    }
}
#endif
