//
//  LoggedInPasteLinkScreen.swift
//  Approver
//
//  Created by Anton Onyshchenko on 07.11.23.
//

import SwiftUI

struct LoggedInPasteLinkScreen: View {
    @Environment(\.apiProvider) var apiProvider
    var session: Session
    var user: API.GuardianUser
    var onUrlPasted: (URL) -> Void
    
    @GestureState var accountPress = false
    @State var showDeactivateAndDelete = false
    @State var showDeactivateAndDeleteConfirmation = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var continuePressed = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            if continuePressed {
                Image(systemName: "square.and.arrow.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100)
                
                Text("To continue, the person you are assisting must send you a link.\n\nOnce you receive it, you can tap on it to continue.\n\nOr, simply copy the link to the clipboard and paste using the button below.")
                    .font(.title3)
                    .padding(30)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                
                PasteLinkButton {url in
                    continuePressed = false
                    onUrlPasted(url)
                }
                    .padding(30)
            } else {
                
                Text("Hello Approver!")
                    .font(.largeTitle)
                Text("You’re helping someone who trusts you keep their crypto safe.\n\n Please tap the continue button when they contact you.")
                    .font(.title3)
                    .padding(30)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    continuePressed = true
                } label: {
                    Text("Continue")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
            }
            Spacer()
            
            if user.guardianStates.countExternalApprovers() > 0 {
                VStack(spacing: 12) {
                    Image("TwoPeople")
                        .frame(width: 32, height: 32)
                    
                    Text("Active approver")
                        .font(.system(size: 14))
                        .bold()
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .updating($accountPress) { currentState, gestureState, transaction in
                            gestureState = currentState
                        }
                        .onEnded {_ in
                            showDeactivateAndDelete = true
                        }
                )
            }
        }
        .padding()
        .confirmationDialog(
            Text("Deactivate and delete?"),
            isPresented: $showDeactivateAndDelete
        ) {
            Button("Deactivate & Delete", role: .destructive) {
                showDeactivateAndDeleteConfirmation = true
            }
        }
        .alert("Deactivate & Delete", isPresented: $showDeactivateAndDeleteConfirmation) {
            Button {
                apiProvider.request(with: session, endpoint: .deleteUser) {result in
                    showDeactivateAndDelete = false
                    switch result {
                    case .success:
                        NotificationCenter.default.post(name: Notification.Name.deleteUserDataNotification, object: nil)
                    case .failure(let error):
                        self.showingError = true
                        self.error = error
                    }
                }
            } label: { Text("Confirm") }
            Button {
                showDeactivateAndDelete = false
            } label: { Text("Cancel") }
        } message: {
            Text("You are about to permanently delete your data and stop being an approver. THIS CANNOT BE UNDONE! The seed phrases you are helping to protect may become inaccessible if you confirm this action.\nAre you sure?")
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel, action: {})
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

#if DEBUG
#Preview("onboarding") {
    LoggedInPasteLinkScreen(
        session: .sample,
        user: API.GuardianUser(guardianStates: []),
        onUrlPasted: { _ in }
    )
}

#Preview("onboarded") {
    LoggedInPasteLinkScreen(
        session: .sample,
        user: API.GuardianUser(guardianStates: [
            .init(
                participantId: .random(),
                phase: .complete
            )
        ]),
        onUrlPasted: { _ in }
    )
}

extension Session {
    static var sample: Self {
        .init(deviceKey: .sample, userCredentials: .sample)
    }
}

extension UserCredentials {
    static var sample: Self {
        .init(idToken: Data() , userIdentifier: "identifier")
    }
}

extension ParticipantId {
    static var sample: Self {
        try! .init(value: "2FdCBCBb8cE32e1d4D2c82BF0Ee7c6CDBfaB01DB3e9C5B2C0CccbE2CD4bFBa1f")
    }
}
#endif
