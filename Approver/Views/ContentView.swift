//
//  ContentView.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

struct ContentView: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var identifier: String = ""
    @State private var route: ApproverRoute = .initial
    @State private var participantId: ParticipantId = .random()
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var attemptingURL: URL?
    @State private var isPresented = false
    
    var body: some View {
        Authentication { session in
            CloudCheck {
                NavigationStack {
                    ApproverHome(
                        session: session,
                        onUrlPasted: { url in openURL(url) }
                    )
                    .navigationDestination(
                        isPresented: $isPresented,
                        destination: {
                            ApproverRouting(
                                inviteCode: $identifier,
                                participantId: $participantId,
                                route: $route,
                                session: session,
                                onSuccess: {
                                    isPresented = false
                                }
                            )
                        }
                    )
                }
                .onOpenURL(perform: openURL)
                .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
                    Button("OK", role: .cancel, action: {})
                } message: { error in
                    Text(error.localizedDescription)
                }
            }
        }
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
        
        self.identifier = url.pathComponents[1]
        checkIdentifier(route: action == "invite" ? .onboard : .access)
    }

    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }
    
    private func checkIdentifier(route: ApproverRoute) {
        self.route = route
        switch route {
        case .onboard:
            if self.identifier.starts(with: "invitation_") {
                self.isPresented = true
            } else {
                showError(CensoError.invalidIdentifier)
            }
        case .access:
            if let participantId = try? ParticipantId(value: self.identifier) {
                self.participantId = participantId
                self.isPresented = true
            } else {
                showError(CensoError.invalidIdentifier)
            }
        default:
            showError(CensoError.invalidIdentifier)
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
