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
    case approval(participantId: ParticipantId, approvalId: String)
    case takeoverInitiation(participantId: ParticipantId, takeoverId: TakeoverId)
    case takeoverVerification(participantId: ParticipantId, takeoverId: TakeoverId)
}

struct ContentView: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var route: ApproverRoute?
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var url: URL?
    @State private var showLogin: Bool = false
    @State private var navigateToRoute = false
    @State private var reloadNeeded = false
    @State private var showLoggedInWelcome = true
    
    var body: some View {
        Authentication(
            loggedOutContent: { onSuccess in
                if showLogin {
                    NavigationView {
                        Login(
                            onSuccess: {
                                self.showLoggedInWelcome = false
                                onSuccess()
                            }
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                DismissButton(icon: .back, action: {
                                    self.showLogin = false
                                })
                            }
                        }
                    }
                } else {
                    LoggedOutWelcomeScreen(
                        onContinue: {
                            self.showLogin = true
                        }
                    )
                    .onOpenURL(perform: {
                        self.url = $0
                    })
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
                                    LoggedInView(
                                        session: session,
                                        onUrlPasted: { url in openURL(url) },
                                        reloadNeeded: $reloadNeeded,
                                        showWelcome: $showLoggedInWelcome
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
                                    case .approval(let participantId, let approvalId):
                                        Approval(
                                            session: session,
                                            participantId: participantId,
                                            approvalId: approvalId,
                                            onSuccess: {
                                                navigateToRoute = false
                                                self.route = nil
                                            }
                                        )
                                    case .takeoverInitiation(let participantId, let takeoverId):
                                        TakeoverInitiation(
                                            session: session,
                                            participantId: participantId,
                                            takeoverId: takeoverId,
                                            onSuccess: {
                                                navigateToRoute = false
                                                self.route = nil
                                            }
                                        )
                                    case .takeoverVerification(let participantId, let takeoverId):
                                        TakeoverVerification(
                                            session: session,
                                            participantId: participantId,
                                            takeoverId: takeoverId,
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
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.maintenanceStatusCheckNotification)) { _ in
                    apiProvider.request(with: session, endpoint: .health) { _ in }
                }
            }
        )
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {
                self.currentError = nil
                self.showingError = false
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
              ["invite", "access", "auth-reset", "takeover-initiation", "takeover-verification"].contains(action) else {
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
        } else if ["access", "auth-reset"].contains(action) {
            if url.pathComponents.count <= 3 {
                showError(CensoError.invalidUrl(url: "\(url)"))
                return
            }
            if let participantId = try? ParticipantId(value: url.pathComponents[2]) {
                self.route = .approval(participantId: participantId, approvalId: url.pathComponents[3])
                self.navigateToRoute = true
            } else {
                SentrySDK.captureWithTag(error: CensoError.invalidIdentifier, tagValue: "Other Link Paste")
                showError(CensoError.invalidIdentifier)
            }
        } else if ["takeover-initiation"].contains(action) {
            if url.pathComponents.count <= 3 {
                showError(CensoError.invalidUrl(url: "\(url)"))
                return
            }
            if let participantId = try? ParticipantId(value: url.pathComponents[2]) {
                self.route = .takeoverInitiation(participantId: participantId, takeoverId: url.pathComponents[3])
                self.navigateToRoute = true
            } else {
                SentrySDK.captureWithTag(error: CensoError.invalidIdentifier, tagValue: "Other Link Paste")
                showError(CensoError.invalidIdentifier)
            }
        } else if ["takeover-verification"].contains(action) {
            if url.pathComponents.count <= 3 {
                showError(CensoError.invalidUrl(url: "\(url)"))
                return
            }
            if let participantId = try? ParticipantId(value: url.pathComponents[2]) {
                self.route = .takeoverVerification(participantId: participantId, takeoverId: url.pathComponents[3])
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
