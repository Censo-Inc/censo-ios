//
//  GuardianConfirmation.swift
//  Vault
//
//  Created by Brendan Flood on 9/11/23.
//

import SwiftUI
import Moya

struct GuardianOnboarding: View {
    
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var currentDate: Date = Date()
    @State private var guardianStatus: API.GuardianStatus = .initial
    @State private var accepted = false
    @State private var invitationId: String?
    @State private var loadingState: LoadingState = .loading
    @State private var confirmationSucceeded: Bool = false
    @State private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var totpSecret: Data?

    var session: Session
    var guardian: API.ProspectGuardian
    var onSuccess: () -> Void
    
    enum LoadingState {
        case loading
        case loaded
    }
    
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        VStack(spacing: 50) {
            switch(loadingState) {
            case .loading:
                ProgressView()
            case .loaded:
                List {
                    Section(header: Text("Invitation").bold().foregroundColor(Color.black)) {
                        if accepted {
                            Text("\(guardian.label) Accepted")
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if let inviteId = invitationId,
                           let link = URL(string: "censo-guardian://invite/\(inviteId)") {
                            ShareLink(item: link,
                                      subject: Text("Censo Invitation Link for \(guardian.label)"),
                                      message: Text("Censo Invitation Link for \(guardian.label)")
                            ){
                                Text("Share Invitation Link")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        } else {
                            Text("Invitation Pending")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }.multilineTextAlignment(.center)
                    Section(header: Text("Code Verification").bold().foregroundColor(Color.black)) {
                        if !accepted {
                            Text("Waiting for \(guardian.label) to accept")
                        } else if let totpSecret = totpSecret {
                            Text("Have them enter this code into the Guardian app.")
                                .frame(maxWidth: .infinity, alignment: .center)
                            HStack {
                                Text(TotpUtils.getOTP(date: currentDate, secret: totpSecret)).font(.title)
                                Spacer()
                                Text("\(TotpUtils.getRemainingSeconds(date: currentDate))")
                                    .font(.title)
                            }
                        } else {
                            Text("Code Pending")
                        }
                    }
                    Section(header: Text("Verification Status").bold().foregroundColor(Color.black)) {
                        switch(guardianStatus) {
                        case .verificationSubmitted(let status):
                            switch (status.verificationStatus) {
                            case .waitingForVerification:
                                Text("Verification Pending")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            case .notSubmitted:
                                Text("Not Confirmed")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            case .rejected:
                                Text("Verification failed for \(guardian.label). They will try again")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(Color.red)
                            case .verified:
                                EmptyView()
                            }
                        default:
                            Text("Not Confirmed")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }.multilineTextAlignment(.center)
                    
                }.multilineTextAlignment(.center)
            }
        }
        .navigationBarTitle("Onboarding \(guardian.label)", displayMode: .inline)
        .padding()
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
        .onReceive(timerPublisher) { _ in
            currentDate = Date()
        }
        .onReceive(remoteNotificationPublisher) { _ in
            reloadUser()
        }
        .onReceive(refreshStatePublisher) { _ in
            reloadUser()
        }
        .onAppear {
            loadingState = .loading
            reloadUser()
        }
        .onDisappear() {
            timerPublisher.upstream.connect().cancel()
            refreshStatePublisher.upstream.connect().cancel()
        }
    }
    
    private func confirmGuardianship(participantId: ParticipantId, status: API.GuardianStatus.VerificationSubmitted) {
        do {
            confirmationSucceeded = try verifyGuardianSignature(status: status)
        } catch {
            confirmationSucceeded = false
        }

        if confirmationSucceeded {
            let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
            guard let participantIdData = participantId.value.data(using: .hexadecimal),
                  let timeMillisData = String(timeMillis).data(using: .utf8),
                  let signature = try? session.deviceKey.signature(for: status.guardianPublicKey.data + participantIdData + timeMillisData) else {
                confirmationSucceeded = false
                return
            }
            apiProvider.decodableRequest(
                with: session,
                endpoint: .confirmGuardian(
                    API.ConfirmGuardianApiRequest(
                        participantId: participantId,
                        keyConfirmationSignature: Base64EncodedString(data: signature),
                        keyConfirmationTimeMillis: timeMillis
                    )
                )
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(ownerState: response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
        } else {
            rejectGuardianVerification()
        }
    }
    
    
    private func verifyGuardianSignature(status: API.GuardianStatus.VerificationSubmitted) throws -> Bool {
        guard let totpSecret = totpSecret,
              let timeMillisBytes = String(status.timeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.guardianPublicKey) else {
            return false
        }
        
        let acceptedDate = Date(timeIntervalSince1970: Double(status.timeMillis) / 1000.0)
        for date in [acceptedDate, acceptedDate - TotpUtils.period, acceptedDate + TotpUtils.period] {
            if let codeBytes = TotpUtils.getOTP(date: date, secret: totpSecret).data(using: .utf8) {
                if try publicKey.verifySignature(for: codeBytes + timeMillisBytes, signature: status.signature) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func inviteGuardian() {
        guard let secret = try? generateBase32().decodeBase32(),
              let deviceEncryptedTotpSecret = try? session.deviceKey.encrypt(data: secret) else {
            showError(PolicySetupError.cannotCreateTotpSecret)
            return
        }
        apiProvider.decodableRequest(
            with: session,
            endpoint: .inviteGuardian(
                API.InviteGuardianApiRequest(
                    participantId: guardian.participantId,
                    deviceEncryptedTotpSecret: deviceEncryptedTotpSecret
                )
            )
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(ownerState: response.ownerState)
                    loadingState = .loaded
                case .failure(let error):
                    showError(error)
                }
            }
    }
    
    private func rejectGuardianVerification() {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .rejectGuardianVerification(guardian.participantId)
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(ownerState: response.ownerState)
                    loadingState = .loaded
                case .failure(let error):
                    showError(error)
                }
            }
    }
    
    private func reloadUser() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdate(ownerState: user.ownerState)
            case .failure:
                break;
            }
        }
    }
    
    private func onOwnerStateUpdate(ownerState: API.OwnerState?) {
        if let ownerState = ownerState {
            switch(ownerState) {
            case .guardianSetup(let guardianSetup):
                if let prospectGuardian = guardianSetup.guardians.first(where: {$0.participantId == guardian.participantId}) {
                    if (self.invitationId != prospectGuardian.invitationId) {
                        self.invitationId = prospectGuardian.invitationId
                        if let deviceEncryptedTotpSecret = prospectGuardian.deviceEncryptedTotpSecret,
                           let totpSecret = try? session.deviceKey.decrypt(data: deviceEncryptedTotpSecret.data) {
                            self.totpSecret = totpSecret
                        }
                    }
                    switch (prospectGuardian.status) {
                    case .declined,
                         .confirmed,
                         .onboarded:
                        onSuccess()
                    case .invited,
                         .initial:
                        if self.invitationId == nil {
                            inviteGuardian()
                        } else {
                            loadingState = .loaded
                        }
                    case .verificationSubmitted(let verificationSubmitted):
                        loadingState = .loaded
                        if verificationSubmitted.verificationStatus == .waitingForVerification {
                            confirmGuardianship(participantId: prospectGuardian.participantId, status: verificationSubmitted)
                        }
                        accepted = true
                    case .accepted:
                        loadingState = .loaded
                        accepted = true
                    }
                    guardianStatus = prospectGuardian.status
                }
            default:
                onSuccess()
            }
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        
        self.error = error
        self.showingError = true
    }
}
