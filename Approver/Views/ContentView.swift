//
//  ContentView.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

enum ApproverRoute : Hashable {
    case onboard(inviteCode: String)
    case access(participantId: ParticipantId)
}

struct ContentView: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var route: ApproverRoute?
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var url: URL?
    @State private var navigateToRoute = false
    
    var body: some View {
        Authentication(
            loggedOutContent: { onSuccess in
                if url == nil {
                    LoggedOutPasteLinkScreen(
                        onUrlPasted: { url in
                            self.url = url
                        }
                    )
                } else {
                    Login(onSuccess: onSuccess)
                }
            },
            loggedInContent: { session in
                CloudCheck {
                    NavigationView {
                        VStack {
                            if let url {
                                ProgressView()
                                    .onAppear {
                                        self.url = nil
                                        openURL(url)
                                    }
                            } else {
                                ApproverHome(
                                    session: session,
                                    onUrlPasted: { url in openURL(url) }
                                )
                            }
                            
                            NavigationLink(isActive: $navigateToRoute) {
                                switch (route) {
                                case .onboard(let inviteCode):
                                    Onboarding(
                                        session: session,
                                        inviteCode: inviteCode,
                                        onSuccess: {
                                            navigateToRoute = false
                                            self.route = nil
                                        }
                                    )
                                case .access(let participantId):
                                    AccessApproval(
                                        session: session,
                                        participantId: participantId,
                                        onSuccess: {
                                            navigateToRoute = false
                                            self.route = nil
                                        }
                                    )
                                case nil:
                                    ProgressView()
                                        .onAppear {
                                            navigateToRoute = false
                                            self.route = nil
                                        }
                                }
                            } label: {
                                EmptyView()
                            }
                        }
                    }
                    .onOpenURL(perform: openURL)
                    .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
                        Button("OK", role: .cancel, action: {
                            self.url = nil
                        })
                    } message: { error in
                        Text(error.localizedDescription)
                    }
                }
            }
        )
    }

    private func openURL(_ url: URL) {
        guard let scheme = url.scheme,
              scheme.starts(with: "censo"),
              url.pathComponents.count > 1,
              let action = url.host,
              ["invite", "access"].contains(action) else {
            showError(CensoError.invalidUrl)
            return
        }
        
        let identifier = url.pathComponents[1]
        
        if action == "invite" {
            if identifier.starts(with: "invitation_") {
                self.route = .onboard(inviteCode: identifier)
                self.navigateToRoute = true
            } else {
                showError(CensoError.invalidIdentifier)
            }
        } else {
            if let participantId = try? ParticipantId(value: identifier) {
                self.route = .access(participantId: participantId)
                self.navigateToRoute = true
            } else {
                showError(CensoError.invalidIdentifier)
            }
        }
    }

    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
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
