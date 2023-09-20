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
                        if let inviteId = invitationId,
                           let link = URL(string: "vault://guardian/\(inviteId)") {
                            ShareLink(item: link,
                                      subject: Text("Censo Invitation Link for \(guardian.label)"),
                                      message: Text("Censo Invitation Link for \(guardian.label)")
                            ){
                                Text("Share Invitation Link")
                            }
                        } else {
                            Text("Invitation Pending")
                        }
                    }
                    Section(header: Text("Code Verification").bold().foregroundColor(Color.black)) {
                        if let totpSecret = totpSecret {
                            Text("Once \(guardian.label) is ready to be confirmed, please provide the below code").font(.title2).multilineTextAlignment(.center)
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
                    Section(header: Text("Confirmation Status").bold().foregroundColor(Color.black)) {
                        switch(guardianStatus) {
                        case .accepted:
                            if confirmationSucceeded {
                                Text("Confirmation Pending")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Text("Confirmation failed for \(guardian.label). Have them try again.")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(Color.red)
                            }
                        default:
                            Text("Not Confirmed")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }.multilineTextAlignment(.center)
                    
                }
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
    
    private func confirmGuardianship(participantId: ParticipantId, accepted: API.GuardianStatus.Accepted) {
        do {
            confirmationSucceeded = try verifyGuardianSignature(accepted: accepted)
        } catch {
            confirmationSucceeded = false
        }

        if confirmationSucceeded {
            let timeMillis = UInt64(Date().timeIntervalSince1970 / 1000)
            guard let participantIdData = participantId.value.data(using: .hexadecimal),
                  let timeMillisData = String(timeMillis).data(using: .utf8),
                  let signature = try? session.deviceKey.signature(for: accepted.guardianPublicKey.data + participantIdData + timeMillisData) else {
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
        }
    }
    
    
    private func verifyGuardianSignature(accepted: API.GuardianStatus.Accepted) throws -> Bool {
        guard let totpSecret = totpSecret,
              let timeMillisBytes = String(accepted.timeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: accepted.guardianPublicKey) else {
            return false
        }
        
        let acceptedDate = Date(timeIntervalSince1970: Double(accepted.timeMillis) / 1000.0)
        for date in [acceptedDate, acceptedDate - TotpUtils.period, acceptedDate + TotpUtils.period] {
            if let codeBytes = TotpUtils.getOTP(date: date, secret: totpSecret).data(using: .utf8) {
                if try publicKey.verifySignature(for: codeBytes + timeMillisBytes, signature: accepted.signature) {
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
                    case .accepted(let accepted):
                        loadingState = .loaded
                        confirmGuardianship(participantId: prospectGuardian.participantId, accepted: accepted)
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
