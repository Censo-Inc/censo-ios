//
//  GuardianSetup.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

struct GuardianVerification: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var guardianStatus: API.GuardianPhase = .waitingForCode(API.GuardianPhase.WaitingForCode(invitationId: ""))
    @State private var loadingState: LoadingState = .loading
    @State private var verificationCode: String = ""
    @State private var verificationStatus = VerificationStatus.notSubmitted
    @State private var guardianKey: EncryptionKey?
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @FocusState var isFocused

    var session: Session
    var inviteCode: String
    var onSuccess: () -> Void
    
    enum LoadingState {
        case loading
        case loaded
    }
        
    var body: some View {
        VStack(spacing: 50) {
            switch(loadingState) {
            case .loading:
                ProgressView()
            case .loaded:
                List {
                    
                    Section(header: Text("Your private key").bold().foregroundColor(Color.black)) {
                        if let guardianKey = guardianKey {
                            Text("Guardian Key Created  ....\(String((try! guardianKey.privateKeyRaw().toHexString()).dropFirst(56)))")
                        } else {
                            Text("Guardian Key Not Created")
                        }
                    }
                    
                    Section(header: Text("Code Verification").bold().foregroundColor(Color.black)) {
                        HStack(spacing: 3) {
                            TextField("Enter Verification Code", text: $verificationCode)
                                .focused($isFocused)
                                .font(.title3)
                            Button("Submit") {
                                isFocused = false
                                submitVerificaton(code: verificationCode)
                            }
                            .disabled(verificationCode.count != 6 || verificationStatus == .waitingForVerification || verificationStatus == .verified)
                            .buttonStyle(FilledButtonStyle())
                        }
                    }
                    
                    if verificationStatus != .notSubmitted {
                        Section(header: Text("Verification Status").bold().foregroundColor(Color.black)) {
                            switch(verificationStatus) {
                            case .notSubmitted:
                                EmptyView()
                            case .waitingForVerification:
                                Text("Verification Pending")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            case .rejected:
                                Text("Verification failed. Please re-enter the code or request a new one")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(Color.red)
                            case .verified:
                                Text("Verified")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .foregroundColor(Color.green)
                            }
                        }.multilineTextAlignment(.center)
                    }
                    
                }
            }
        }
        .navigationBarTitle("Guardian Verification", displayMode: .inline)
        .padding()
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
        .onReceive(refreshStatePublisher) { _ in
            reloadUser()
        }
        .onAppear {
            loadingState = .loading
            reloadUser()
        }
        .onDisappear() {
            refreshStatePublisher.upstream.connect().cancel()
        }
    }
    
    private func submitVerificaton(code: String) {
        
        let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
        guard let codeBytes = code.data(using: .utf8),
              let timeMillisData = String(timeMillis).data(using: .utf8),
              let guardianPublicKey = try? guardianKey?.publicExternalRepresentation(),
              let signature = try? guardianKey?.signature(for: codeBytes + timeMillisData) else {
            showError(GuardianError.failedToCreateSignature)
            return
        }
        
        apiProvider.decodableRequest(
            with: session,
            endpoint: .submitVerification(
                inviteCode,
                API.SubmitGuardianVerificationApiRequest(
                    signature: signature,
                    timeMillis: timeMillis,
                    guardianPublicKey: guardianPublicKey
                )
            )
        ) { (result: Result<API.SubmitGuardianVerificationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onGuardianStateUpdate(guardianStates: [response.guardianState])
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func reloadUser() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.GuardianUser, MoyaError>) in
            switch result {
            case .success(let user):
                onGuardianStateUpdate(guardianStates: user.guardianStates)
                loadingState = .loaded
            case .failure:
                break;
            }
        }
    }
    
    private func onGuardianStateUpdate(guardianStates: [API.GuardianState]) {
        if guardianKey == nil {
            guardianKey = try? EncryptionKey.generateRandomKey()
        }
        if let guardianPhase = guardianStates.forInvite(inviteCode)?.phase {
            switch(guardianPhase) {
            case .waitingForCode:
                break
            case .waitingForConfirmation(let data):
                verificationStatus = data.verificationStatus
            case .complete:
                onSuccess()
            }
        } else {
            onSuccess()
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        
        self.error = error
        self.showingError = true
    }
}

//#if DEBUG
//struct GuardianSetup_Previews: PreviewProvider {
//    static var previews: some View {
//        GuardianSetup(deviceKey: .sample)
//    }
//}
//#endif

