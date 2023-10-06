//
//  PolicySetup.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import SwiftUI
import Moya
import BigInt

struct  GuardianActivation: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    enum SetupState {
        case loading
        case guardianSetup
        case policySetup
    }
    
    @State private var guardianProspects: [API.ProspectGuardian] = []
    @State private var threshold: Int = 0
    @State private var setupState: SetupState = .loading
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var allGuardiansConfirmed = false
    @State private var currentDate: Date = Date()
    @State private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var session: Session
    var onSuccess: () -> Void
    
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        Group {
            switch (setupState) {
            case .loading:
                ProgressView().onAppear { reloadUser() }
            case .policySetup: // this should never be the case
                PolicySetup(
                    session: session,
                    threshold: threshold,
                    approvers: guardianProspects.map(\.label)
                ) { _ in
                    reloadUser()
                }
            case .guardianSetup:
                VStack {
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            setupState = .policySetup
                        } label: {
                            Text("Edit").foregroundColor(Color.blue)
                        }
                    }
                    Section(header: Text("Guardian Activation").bold().foregroundColor(Color.black)) {
                        List {
                            ForEach(guardianProspects, id:\.participantId){ guardian in
                                HStack(alignment: .center, spacing: 5) {
                                    Text(guardian.label)
                                        .frame(height: 60)
                                    switch (guardian.status) {
                                    case .confirmed:
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .renderingMode(.template)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundColor(.Censo.green)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .padding()
                                            .frame(height: 60)
                                    case .declined:
                                        Spacer()
                                        Image(systemName: "xmark.circle.fill")
                                            .renderingMode(.template)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundColor(.Censo.red)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .padding()
                                            .frame(height: 60)
                                    case .initial(let status):
                                        Spacer()
                                        if let link = URL(string: "censo-guardian://invite/\(status.invitationId)") {
                                            ShareLink(item: link,
                                                      subject: Text("Censo Invitation Link for \(guardian.label)"),
                                                      message: Text("Censo Invitation Link for \(guardian.label)")
                                            ){
                                                Image(systemName: "square.and.arrow.up")
                                                
                                            }
                                        }
                                    case .accepted(let status):
                                        RotatingTotpPinView(
                                            session: session,
                                            currentDate: currentDate,
                                            deviceEncryptedTotpSecret: status.deviceEncryptedTotpSecret)
                                    case .verificationSubmitted(let status):
                                        RotatingTotpPinView(
                                            session: session,
                                            currentDate: currentDate,
                                            deviceEncryptedTotpSecret: status.deviceEncryptedTotpSecret)
                                    default:
                                        Text("")
                                    }
                                }
                            }
                        }
                    }
                
                    Spacer()
                    
                    Button {
                        createPolicy()
                    } label: {
                        if inProgress {
                            ProgressView()
                        } else {
                            Text("Continue")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .frame(height: 44)
                        }
                    }
                    .disabled(!allGuardiansConfirmed || guardianProspects.isEmpty || threshold == 0 || inProgress)
                    .buttonStyle(FilledButtonStyle())
                    
                }
            }
        }
        .navigationBarTitle("Guardian Activation", displayMode: .inline)
        .navigationBarItems(trailing:
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        )
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
        .onDisappear() {
            timerPublisher.upstream.connect().cancel()
            refreshStatePublisher.upstream.connect().cancel()
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false

        self.error = error
        self.showingError = true
    }
    
    private func createPolicy() {
        var policySetupHelper: PolicySetupHelper
        do {
            policySetupHelper = try PolicySetupHelper(
                threshold: threshold,
                guardians: guardianProspects.map({($0.participantId, try getGuardianPublicKey(status: $0.status))})
            )
        } catch {
            showError(error)
            return
        }
        return apiProvider.decodableRequest(with: session, endpoint: .createPolicy(
                API.CreatePolicyApiRequest(
                    intermediatePublicKey: policySetupHelper.intermediatePublicKey,
                    guardianShards: policySetupHelper.guardians,
                    encryptedMasterPrivateKey: policySetupHelper.encryptedMasterPrivateKey,
                    masterEncryptionPublicKey: policySetupHelper.masterEncryptionPublicKey))) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                        switch result {
                        case .success(_):
                            onSuccess()
                        case .failure(let error):
                            showError(error)
                        }
                    }
    }
    
    
    private func onOwnerStateUpdate(ownerState: API.OwnerState?) {
        if let ownerState = ownerState {
            switch(ownerState) {
            case .guardianSetup(let guardianSetup):
                guardianProspects = guardianSetup.guardians
                threshold = guardianSetup.threshold ?? 0
                allGuardiansConfirmed = guardianSetup.guardians.count > 0 && guardianSetup.guardians.allSatisfy({isConfirmed(status: $0.status)})
                for prospectGuardian in guardianSetup.guardians {
                    switch (prospectGuardian.status) {
                    case .verificationSubmitted(let verificationSubmitted):
                        if verificationSubmitted.verificationStatus == .waitingForVerification {
                            confirmGuardianship(participantId: prospectGuardian.participantId, status: verificationSubmitted)
                        }
                    default:
                        break;
                    }
                }
            default:
                onSuccess()
            }
        }
    }

    private func rejectGuardianVerification(participantId: ParticipantId) {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .rejectGuardianVerification(participantId)
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdate(ownerState: response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
    }
    
    private func confirmGuardianship(participantId: ParticipantId, status: API.GuardianStatus.VerificationSubmitted) {
        
        var confirmationSucceeded = false
        do {
            confirmationSucceeded = try verifyGuardianSignature(participantId: participantId, status: status)
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
            rejectGuardianVerification(participantId: participantId)
        }
    }
    
    private func verifyGuardianSignature(participantId: ParticipantId, status: API.GuardianStatus.VerificationSubmitted) throws -> Bool {
        guard let totpSecret = try? session.deviceKey.decrypt(data: status.deviceEncryptedTotpSecret.data),
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
    
    private func isConfirmed(status: API.GuardianStatus) ->  Bool {
        switch(status) {
        case .confirmed:
            return true
        default:
            return false
        }
    }
    
    private func getGuardianPublicKey(status: API.GuardianStatus) throws -> Base58EncodedPublicKey {
        switch(status) {
        case .confirmed(let confirmed):
            return confirmed.guardianPublicKey
        default:
            throw PolicySetupError.badPublicKey
        }
    }
    
    private func reloadUser() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdate(ownerState: user.ownerState)
                if setupState == .loading {
                    setupState = .guardianSetup
                }
            default:
                break
            }
        }
    }
}

#if DEBUG
struct GuardianActivation_Previews: PreviewProvider {
    static var previews: some View {
        GuardianActivation(session: .sample, onSuccess: {})
    }
}
#endif
