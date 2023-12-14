//
//  LoggedInOwnerView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import SwiftUI
import Moya
import raygun4apple

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

    var session: Session

    var body: some View {
        switch ownerStateResource {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let ownerState):
            if (acceptedTermsOfUseVersion == "v0.2") {
                let ownerStateBinding = Binding<API.OwnerState>(
                    get: { ownerState },
                    set: { replaceOwnerState(newOwnerState: $0) }
                )
                PaywallGatedScreen(session: session, ownerState: ownerStateBinding) {
                    BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                        switch pendingImport {
                        case .none:
                            switch importPhase {
                            case .none:
                                switch ownerState {
                                case .initial:
                                    Welcome(
                                        session: session,
                                        ownerState: ownerStateBinding
                                    )
                                case .ready(let ready) where ready.vault.seedPhrases.isEmpty:
                                    FirstPhrase(
                                        ownerState: ready,
                                        session: session,
                                        onComplete: { ownerState in
                                            replaceOwnerState(newOwnerState: ownerState)
                                        }
                                    )
                                case .ready(let ready):
                                    HomeScreen(
                                        session: session,
                                        ownerState: ready,
                                        onOwnerStateUpdated: { ownerState in
                                            replaceOwnerState(newOwnerState: ownerState)
                                            reload()
                                        }
                                    )
                                }
                            case .completed(let importedPhrase):
                                switch ownerState {
                                case .ready(let ownerState):
                                    if let words = try? BIP39.binaryDataToWords(binaryData: importedPhrase.binaryPhrase.bigInt.magnitude.serialize()) {
                                        NavigationStack {
                                            SeedVerification(
                                                words: words,
                                                session: session,
                                                publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                                                isFirstTime: false,
                                                onClose: { importPhase = .none }
                                            ) { ownerState in
                                                replaceOwnerState(newOwnerState: ownerState)
                                                importPhase = .none
                                            }
                                        }
                                    } else {
                                        ProgressView().onAppear {
                                            importPhase = .none
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
                    .modifier(RefreshOnTimer(timer: $refreshStatePublisher, interval: 1, refresh: checkForCompletedImport))
                }
            } else {
                NavigationStack {
                    TermsOfUse(
                        text: TermsOfUse.v0_2,
                        onAccept: {
                            acceptedTermsOfUseVersion = "v0.2"
                        }
                    )
                    .navigationTitle("Terms of Use")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
            SignIn(session: session, onSuccess: reload) {
                ProgressView("Signing in...")
            }
        case .failure(let error):
            RetryView(error: error, action: reload)
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
                    RaygunClient.sharedInstance().send(error: error, tags: ["Import"], customData: nil)
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
