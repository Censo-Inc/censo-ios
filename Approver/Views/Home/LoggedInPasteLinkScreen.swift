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
    @Binding var user: API.ApproverUser
    var onUrlPasted: (URL) -> Void
    
    @GestureState var accountPress = false
    @State private var continuePressed = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if continuePressed {
                    Spacer()
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
                
                Group {
                    ApproverStatus(active: user.approverStates.countActiveApprovers() > 0)
                    
                    Spacer()
                    
                    NavigationLink {
                        Settings(session: session, user: $user)
                    } label: {
                        HStack {
                            Image("SettingsFilled").renderingMode(.template)
                            Text("Settings")
                                .font(.title3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
            .padding()
        }
    }
}

struct ApproverStatus: View {
    var active: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if active {
                Image("TwoPeople")
                    .renderingMode(.template)
                    .frame(width: 32, height: 32)
                Text("Active approver")
                    .font(.system(size: 14))
                    .bold()
            } else {
                Image("TwoPeople")
                    .frame(width: 32, height: 32)
                    .opacity(0.2)
                Text("Not an active approver")
                    .font(.system(size: 14))
                    .bold()
            }
        }
    }
}

#if DEBUG
#Preview("onboarding") {
    @State var user = API.ApproverUser(approverStates: [])    
    
    return LoggedInPasteLinkScreen(
        session: .sample,
        user: $user,
        onUrlPasted: { _ in }
    )
    .foregroundColor(.Censo.primaryForeground)
}

#Preview("onboarded") {
    @State var user = API.ApproverUser(approverStates: [
        .init(
            participantId: .random(),
            phase: .complete
        )
    ])
    
    return LoggedInPasteLinkScreen(
        session: .sample,
        user: $user,
        onUrlPasted: { _ in }
    )
    .foregroundColor(.Censo.primaryForeground)
}

#Preview("onboarded, multiple owners") {
    @State var user = API.ApproverUser(approverStates: [
        .init(
            participantId: .random(),
            phase: .complete
        ),
        .init(
            participantId: .random(),
            phase: .complete,
            ownerLabel: "John Doe"
        )
    ])
    
    return LoggedInPasteLinkScreen(
        session: .sample,
        user: $user,
        onUrlPasted: { _ in }
    )
    .foregroundColor(.Censo.primaryForeground)
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
