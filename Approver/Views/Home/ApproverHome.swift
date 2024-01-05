//
//  ApproverHome.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

struct ApproverHome: View {
    @Environment(\.apiProvider) var apiProvider
    var session: Session
    @Binding var user: API.ApproverUser
    var onUrlPasted: (URL) -> Void
    
    @State private var showOwnerLoginIdReset = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                if user.isActiveApprover {
                    Text("Received a link?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("If the person you are assisting has sent you a link, you can tap on it to continue.\n\nOr, simply copy the link to the clipboard and paste using the button below.")
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                    
                } else {
                    Image(systemName: "square.and.arrow.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                    
                    Text("To continue, the person you are assisting must send you a link.\n\nOnce you receive it, you can tap on it to continue.\n\nOr, simply copy the link to the clipboard and paste using the button below.")
                        .font(.title3)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                PasteLinkButton {url in
                    onUrlPasted(url)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                if user.isActiveApprover {
                    Divider()
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Text("Asked for login assistance?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Button {
                        showOwnerLoginIdReset = true
                    } label: {
                        Text("Assist")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .padding(.vertical)
            .sheet(isPresented: $showOwnerLoginIdReset, content: {
                OwnerLoginIdReset(session: session, user: $user)
            })
        }
    }
}

#if DEBUG
#Preview("onboarding") {
    @State var user = API.ApproverUser(approverStates: [])    
    
    return ApproverHome(
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
    
    return ApproverHome(
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
    
    return ApproverHome(
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
