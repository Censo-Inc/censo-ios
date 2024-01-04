//
//  ContentView.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya
import Sentry

enum ApproverRoute : Hashable {
    case onboard(inviteCode: String)
    case access(participantId: ParticipantId, approvalId: String)
}

struct ContentView: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var route: ApproverRoute?
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var url: URL?
    @State private var navigateToRoute = false
    @State private var reloadNeeded = false
    
    var body: some View {
        Authentication(
            loggedOutContent: { onSuccess in
                if url == nil {
                    LoggedOutPasteLinkScreen(
                        onUrlPasted: { url in
                            self.url = url
                        }
                    )
                    .onOpenURL(perform: {
                        self.url = $0
                    })
                } else {
                    Login(onSuccess: onSuccess)
                }
            },
            loggedInContent: { session in
                CloudCheck {
                    AppAttest(session: session) {
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
                                        onUrlPasted: { url in openURL(url) },
                                        reloadNeeded: $reloadNeeded
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
                                                self.reloadNeeded = true
                                            }
                                        )
                                    case .access(let participantId, let approvalId):
                                        AccessApproval(
                                            session: session,
                                            participantId: participantId,
                                            approvalId: approvalId,
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
                    }
                }
            }
        )
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {
                self.url = nil
            })
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func openURL(_ url: URL) {
        guard let scheme = url.scheme else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }
        if scheme.starts(with: "https") {
            guard let query = url.query(),
                  query.hasPrefix("l="),
                  let link = String(query.trimmingPrefix("l=")).removingPercentEncoding,
                  let newUrl = URL(string: link) else {
                showError(CensoError.invalidUrl(url: "\(url)"))
                return
            }
            openURL(newUrl)
            return
        }
        guard scheme.starts(with: "censo"),
              url.pathComponents.count > 1,
              let action = url.host,
              ["invite", "access"].contains(action) else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }
        
        let identifier = url.pathComponents[1]
        
        if action == "invite" {
            if identifier.starts(with: "invitation_") {
                self.route = .onboard(inviteCode: identifier)
                self.navigateToRoute = true
            } else {
                SentrySDK.captureWithTag(error: CensoError.invalidIdentifier, tagValue: "Invite Link Paste")
                showError(CensoError.invalidIdentifier)
            }
        } else {
            if url.pathComponents.count <= 3 {
                showError(CensoError.invalidUrl(url: "\(url)"))
                return
            }
            if let participantId = try? ParticipantId(value: url.pathComponents[2]) {
                self.route = .access(participantId: participantId, approvalId: url.pathComponents[3])
                self.navigateToRoute = true
            } else {
                SentrySDK.captureWithTag(error: CensoError.invalidIdentifier, tagValue: "Other Link Paste")
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
