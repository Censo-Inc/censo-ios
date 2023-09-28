//
//  ContentView.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

struct ContentView: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var inviteCode: String = ""
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var attemptingURL: URL?
    @State private var isPresented = false

    @RemoteResult<API.GuardianUser, API> private var user

    var body: some View {
        NavigationStack {
            Invitation(inviteCode: $inviteCode, onValidateCode: checkInviteCode)
                .navigationDestination(isPresented: $isPresented, destination: {
                    Authentication { session in
                        Guardian(
                            inviteCode: $inviteCode,
                            session: session,
                            onSuccess: {
                                isPresented = false
                            }
                        )
                    }
                })
        }
        .onOpenURL(perform: openURL)
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {})
        } message: { error in
            Text(error.localizedDescription)
        }

    }

    private func openURL(_ url: URL) {
        guard url.pathComponents.count > 1,
              let action = url.host,
            action == "invite" else {
            return
        }

        self.inviteCode = url.pathComponents[1]
        checkInviteCode()
    }

    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }
    
    private func checkInviteCode() {
        if (self.inviteCode.starts(with: "invitation_")) {
            self.isPresented = true
        } else {
            self.isPresented = false
            self.showingError = true
            self.currentError = CensoError.invalidInvitationCode
        }
        
    }

}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension CommandLine {
    static var isTesting: Bool = {
        arguments.contains("testing")
    }()
}
#endif
