//
//  Invitation.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

enum  GuardianRoute {
    case initial
    case onboard
    case recovery
}


struct GuardianHome: View {
    @Environment(\.apiProvider) var apiProvider
    
    @State private var showingError = false
    @State private var error: Error?
    
    @RemoteResult<API.GuardianUser, API> private var user
    
    var session: Session
    var onUrlPasted: (URL) -> Void
    
    var body: some View {
        switch user {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let user):
            VStack {
                if user.guardianStates.isEmpty {
                    GuardianHomeInvitation()
                } else {
                    GuardianHomeInvitation()
                }
                Button {
                    handlePastedInfo()
                } label: {
                    HStack {
                        Spacer()
                        Image("Clipboard")
                            .resizable()
                            .frame(width: 36, height: 36)
                        Text("Paste link")
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.horizontal)
                        Spacer()
                    }
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                handlePushRegistration()
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button("OK", role: .cancel, action: {})
            } message: { error in
                Text(error.localizedDescription)
            }
        case .failure(MoyaError.statusCode(let response)) where response.statusCode == 404:
            SignIn(session: session, onSuccess: reload) {
                ProgressView("Signing in...")
            }
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }
    
    private func handlePastedInfo() {
        guard let pastedInfo = UIPasteboard.general.string,
              let url = URL(string: pastedInfo) else {
            showError(CensoError.invalidUrl)
            return
            
        }
        onUrlPasted(url)
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func handlePushRegistration() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (result, _) in
                        if result {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                } else if settings.authorizationStatus == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func reload() {
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
}

