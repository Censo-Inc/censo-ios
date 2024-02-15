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
    var session: Session
    @Binding var pendingImport: Import?
    @Binding var beneficiaryInvitationId: BeneficiaryInvitationId?
    
    var body: some View {
        // We wrap internal view here to inject MoyaProvider from the environment into its initializer
        // This has to do with AppAttest sitting between ContentView and this view
        // and replacing the MoyaProvider in the environment with one that knows about attestation
        InternalView(
            apiProvider: apiProvider,
            session: session,
            pendingImport: $pendingImport,
            beneficiaryInvitationId: $beneficiaryInvitationId
        )
    }
    
    private struct InternalView: View {
        private var apiProvider: MoyaProvider<API>
        private var session: Session
        @Binding private var pendingImport: Import?
        @Binding private var beneficiaryInvitationId: BeneficiaryInvitationId?
        
        @State private var importPhase: ImportPhase = .none
        @StateObject private var ownerRepository: OwnerRepository
        @StateObject private var ownerStateStore: OwnerStateStore
        @AppStorage("acceptedTermsOfUseVersion") var acceptedTermsOfUseVersion: String = ""
        @State private var refreshStatePublisher = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
        @State private var cancelOnboarding = false
        @State private var cancelKeyRecovery = false
        @State private var showingError = false
        @State private var error: Error?
        @State private var beneficiarySetup = false
        
        init(apiProvider: MoyaProvider<API>, session: Session, pendingImport: Binding<Import?>, beneficiaryInvitationId: Binding<BeneficiaryInvitationId?>) {
            self.apiProvider = apiProvider
            self.session = session
            self._pendingImport = pendingImport
            self._beneficiaryInvitationId = beneficiaryInvitationId
            let ownerRepository = OwnerRepository(apiProvider, session)
            self._ownerRepository = StateObject(wrappedValue: ownerRepository)
            self._ownerStateStore = StateObject(wrappedValue: OwnerStateStore(ownerRepository, session))
        }
        
        var body: some View {
            switch ownerStateStore.loadingState {
            case .idle:
                ProgressView()
                    .onAppear(perform: ownerStateStore.reload)
            case .loading:
                ProgressView()
            case .success(let ownerState):
                VStack {
                    if (acceptedTermsOfUseVersion == "v0.3") {
                        PaywallGatedScreen(ownerState: ownerState, onCancel: onCancelOnboarding) {
                            BiometryGatedScreen(ownerState: ownerState, onUnlockExpired: ownerStateStore.reload) {
                                switch pendingImport {
                                case .none:
                                    switch importPhase {
                                    case .none:
                                        switch ownerState {
                                        case .initial(let initial):
                                            switch beneficiaryInvitationId {
                                            case .none:
                                                Welcome(
                                                    ownerState: initial,
                                                    onCancel: onCancelOnboarding
                                                )
                                            case .some(let invitationId):
                                                BeneficiaryOnboarding(
                                                    beneficiaryInvitationId: invitationId,
                                                    onCancel: {
                                                        beneficiaryInvitationId = nil
                                                    },
                                                    onDelete: {
                                                        cancelOnboarding = true
                                                    }
                                                )
                                            }
                                        case .beneficiary(let beneficiary):
                                            switch beneficiary.phase {
                                            case .accepted,
                                                    .verificationRejected,
                                                    .waitingForVerification:
                                                BeneficiaryVerification(beneficiary: beneficiary)
                                                    .onboardingCancelNavBar {
                                                        cancelOnboarding = true
                                                    }
                                                    .onAppear {
                                                        beneficiarySetup = true
                                                    }
                                            case .activated where beneficiarySetup:
                                                BeneficiaryActivated()
                                            case .activated:
                                                BeneficiaryWelcomeBack()
                                            }
                                        case .ready(let ready):
                                            if ready.policy.ownersApproverKeyRecoveryRequired(ownerRepository) {
                                                NavigationStack {
                                                    OwnerKeyRecovery(
                                                        ownerState: ready
                                                    )
                                                    .navigationInlineTitle("Reset Login ID")
                                                    .toolbar {
                                                        ToolbarItem(placement: .navigationBarLeading) {
                                                            DismissButton(icon: .close, action: {
                                                                cancelKeyRecovery = true
                                                            })
                                                        }
                                                    }
                                                    .deleteAllDataAlert(
                                                        title: "Cancel Key Recovery",
                                                        numSeedPhrases: ready.vault.seedPhrases.count,
                                                        deleteRequested:$cancelKeyRecovery) {
                                                            deleteOwner(ownerRepository, ownerState, onSuccess: {}, onFailure: showError)
                                                        }
                                                }
                                            } else {
                                                if !ready.onboarded {
                                                    FirstPhrase(
                                                        ownerState: ready,
                                                        onCancel: onCancelOnboarding
                                                    )
                                                    
                                                } else {
                                                    HomeScreen(ownerState: ready)
                                                }
                                            }
                                        }
                                    case .completed(let importedPhrase):
                                        switch ownerState {
                                        case .ready(let ready):
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
                                                        ownerState: ready,
                                                        isFirstTime: false,
                                                        requestedLabel: importedPhrase.label,
                                                        onClose: {
                                                            importPhase = .none
                                                        },
                                                        onSuccess: {
                                                            importPhase = .none
                                                        }
                                                    )
                                                }
                                            }
                                        case .initial,
                                                .beneficiary:
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
                            text: TermsOfUse.v0_3,
                            onAccept: {
                                acceptedTermsOfUseVersion = "v0.3"
                            }
                        )
                        .onboardingCancelNavBar(
                            onboarding: ownerState.onboarding,
                            navigationTitle: "Terms of Use",
                            onCancel: onCancelOnboarding
                        )
                    }
                }
                .environmentObject(ownerStateStore.controller())
                .environmentObject(ownerRepository)
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button { } label: { Text("OK") }
                } message: { error in
                    Text(error.localizedDescription)
                }
                .alert("Exit Setup", isPresented: $cancelOnboarding) {
                    Button(role: .destructive) {
                        deleteOwner(ownerRepository, ownerState, onSuccess: {}, onFailure: showError)
                    } label: { Text("Exit") }
                    Button(role: .cancel) {
                    } label: { Text("Cancel") }
                } message: {
                    Text("This will exit the setup process and delete **ALL** of your data. You will be required to start over again.")
                }
            case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                SignIn(session: session, onSuccess: ownerStateStore.reload) {
                    ProgressView("Signing in...")
                }
            case .failure(let error):
                RetryView(error: error, action: ownerStateStore.reload)
            }
        }
        
        private func onCancelOnboarding() {
            cancelOnboarding = true
        }
        
        private func showError(error: Error) {
            self.showingError = true
            self.error = error
        }
        
        private func checkForCompletedImport() {
            switch importPhase {
            case .completing(let accepted):
                ownerRepository.getImportEncryptedData(accepted.channel()) { result in
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
        
        private func acceptImport(importToAccept: Import) {
            importPhase = .accepting
            guard let ownerProofSignature = try? session.deviceKey.signature(for: importToAccept.importKey.data) else {
                importPhase = .none
                return
            }
            ownerRepository.acceptImport(importToAccept.channel(), API.OwnerProof(signature: ownerProofSignature)) { _ in
                importPhase = .completing(importToAccept)
            }
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

struct LoggedInOwnerPreviewContainer<Content : View> : View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .foregroundColor(.Censo.primaryForeground)
            .environmentObject(
                OwnerStateStoreController(replace: { _ in }, reload: {})
            )
            .environmentObject(Session.sample)
            .environmentObject(OwnerRepository(APIProviderEnvironmentKey.defaultValue, Session.sample))
    }
}
#endif
