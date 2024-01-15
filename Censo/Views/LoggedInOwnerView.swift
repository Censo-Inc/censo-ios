//
//  LoggedInOwnerView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import SwiftUI
import Moya
import Sentry

enum ImportPhase {
    case none
    case accepting
    case completing(Import)
    case completed(ImportedPhrase)
}

struct LoggedInOwnerView: View {
    @Environment(\.apiProvider) var apiProvider
    @Binding var pendingImport: Import?
    @State private var importPhase: ImportPhase = .none
    @RemoteResult<API.OwnerState, API> private var ownerStateResource
    @AppStorage("acceptedTermsOfUseVersion") var acceptedTermsOfUseVersion: String = ""
    @State private var refreshStatePublisher = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    @State private var cancelOnboarding = false
    @State private var showingError = false
    @State private var error: Error?

    var session: Session

    var body: some View {
        switch ownerStateResource {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let ownerState):
            VStack {
                if (acceptedTermsOfUseVersion == "v0.2") {
                    let ownerStateBinding = Binding<API.OwnerState>(
                        get: { ownerState },
                        set: { replaceOwnerState(newOwnerState: $0) }
                    )
                    PaywallGatedScreen(session: session, ownerState: ownerStateBinding, onCancel: onCancelOnboarding) {
                        BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                            switch pendingImport {
                            case .none:
                                switch importPhase {
                                case .none:
                                    switch ownerState {
                                    case .initial(let initial):
                                        InitialPlanSetup(
                                            session: session,
                                            ownerState: initial,
                                            onComplete: replaceOwnerState,
                                            onCancel: onCancelOnboarding
                                        )
                                    case .ready(let ready):
                                        if ready.policy.ownersApproverKeyRecoveryRequired(session) {
                                            OwnerKeyRecovery(
                                                session: session,
                                                ownerState: ready,
                                                onOwnerStateUpdated: replaceOwnerState
                                            )
                                        } else {
                                            if ready.vault.seedPhrases.isEmpty {
                                                FirstPhrase(
                                                    ownerState: ready,
                                                    session: session,
                                                    onComplete: replaceOwnerState,
                                                    onCancel: onCancelOnboarding
                                                )
                                                
                                            } else {
                                                HomeScreen(
                                                    session: session,
                                                    ownerState: ready,
                                                    onOwnerStateUpdated: replaceOwnerState
                                                )
                                            }
                                        }
                                    }
                                case .completed(let importedPhrase):
                                    switch ownerState {
                                    case .ready(let ownerState):
                                        if let words = try? BIP39.binaryDataToWords(
                                            // serialize() prepends a sign byte, which binaryDataToWords strips off as
                                            // the language byte. We're passing in an explicit language to use, so that
                                            // byte gets ignored anyway
                                            binaryData: importedPhrase.binaryPhrase.bigInt.serialize(),
                                            language: importedPhrase.language
                                        ) {
                                            NavigationStack {
                                                SeedVerification(
                                                    words: words,
                                                    session: session,
                                                    publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                                                    masterKeySignature: ownerState.policy.masterKeySignature,
                                                    ownerParticipantId: ownerState.policy.owner?.participantId,
                                                    ownerEntropy: ownerState.policy.ownerEntropy,
                                                    isFirstTime: false,
                                                    requestedLabel: importedPhrase.label,
                                                    onClose: { importPhase = .none }
                                                ) { ownerState in
                                                    replaceOwnerState(newOwnerState: ownerState)
                                                    importPhase = .none
                                                }
                                            }
                                        }
                                        case .initial:
                                            ProgressView().onAppear {
                                                importPhase = .none
                                            }
                                        }
                                case .completing, .accepting:
                                    ProgressView("Importing phrase")
                                }
                            case .some(let imp):
                                AcceptImportView(importToAccept: imp, onAccept: { imp in
                                    acceptImport(importToAccept: imp)
                                    pendingImport = nil
                                }, onDecline: {
                                    pendingImport = nil
                                })
                            }
                        }
                        .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: checkForCompletedImport))
                    }
                } else {
                    TermsOfUse(
                        text: TermsOfUse.v0_2,
                        onAccept: {
                            acceptedTermsOfUseVersion = "v0.2"
                        }
                    )
                    .onboardingCancelNavBar(
                        onboarding: ownerState.onboarding,
                        navigationTitle: "Terms of Use",
                        onCancel: onCancelOnboarding
                    )
                }
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert("Exit Setup", isPresented: $cancelOnboarding) {
                Button(role: .destructive) {
                    deleteUser(ownerState: ownerState)
                } label: { Text("Exit") }
                Button(role: .cancel) {
                } label: { Text("Cancel") }
            } message: {
                Text("This will exit the setup process and delete **ALL** of your data. You will be required to start over again.")
            }
        case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
            SignIn(session: session, onSuccess: reload) {
                ProgressView("Signing in...")
            }
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }
    
    private func onCancelOnboarding() {
        cancelOnboarding = true
    }
    
    private func deleteUser(ownerState: API.OwnerState) {
        apiProvider.request(with: session, endpoint: .deleteUser) { result in
            switch result {
            case .success:
                switch ownerState {
                case .ready(let ready):
                    if let ownerTrustedApprover = ready.policy.approvers.first(where: { $0.isOwner }) {
                        session.deleteApproverKey(participantId: ownerTrustedApprover.participantId)
                    }
                default:
                    break
                }
                NotificationCenter.default.post(name: Notification.Name.deleteUserDataNotification, object: nil)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }

    private func checkForCompletedImport() {
        switch importPhase {
        case .completing(let accepted):
            apiProvider.decodableRequest(with: session, endpoint: .getImportEncryptedData(channel: accepted.channel())) { (result: Result<GetImportDataByKeyResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    switch response.importState {
                    case .completed(let completed):
                        if let decryptedData = try? session.deviceKey.decrypt(data: completed.encryptedData.data) {
                            let decoder = JSONDecoder()
                            if let importedPhrase = try? decoder.decode(ImportedPhrase.self, from: decryptedData) {
                                importPhase = .completed(importedPhrase)
                            }
                        }
                    default:
                        break
                    }
                case .failure(let error):
                    SentrySDK.captureWithTag(error: error, tagValue: "Import")
                    importPhase = .none
                }
            }
        case .completed, .none, .accepting:
            break
        }
    }

    private func replaceOwnerState(newOwnerState: API.OwnerState) {
        _ownerStateResource.replace(newOwnerState)
    }
    
    private func reload() {
        _ownerStateResource.reload(
            with: apiProvider,
            target: session.target(for: .user),
            adaptSuccess: { (user: API.User) in user.ownerState }
        )
    }

    private func acceptImport(importToAccept: Import) {
        importPhase = .accepting
        guard let ownerProofSignature = try? session.deviceKey.signature(for: importToAccept.importKey.data) else {
            importPhase = .none
            return
        }
        apiProvider.request(with: session, endpoint: .acceptImport(channel: importToAccept.channel(), ownerProof: API.OwnerProof(signature: ownerProofSignature))) { _ in
            importPhase = .completing(importToAccept)
        }
    }
}

extension Array where Element == API.ProspectApprover {
    var allConfirmed: Bool {
        !contains { approver in
            if case .confirmed = approver.status {
                return false
            } else {
                return true
            }
        }
    }
}

#if DEBUG
extension Base64EncodedString {
    static var sample: Self {
        try! .init(value: "")
    }
}

extension Session {
    static var sample: Self {
        .init(deviceKey: .sample, userCredentials: .sample)
    }
}

extension UserCredentials {
    static var sample: Self {
        .init(idToken: Data(), userIdentifier: "userIdentifier")
    }
}

extension API.PolicySetup {
    static var sample: Self {
        .init(approvers: [.sample], threshold: 2)
    }
}

extension API.ProspectApprover {
    static var sample: Self {
        .init(invitationId: try! InvitationId(value: ""), label: "Jerry", participantId: .random(), status: .declined)
    }
}
#endif
