//
//  BiometryGatedScreen.swift
//  Vault
//
//  Created by Anton Onyshchenko on 27.09.23.
//

import Foundation
import SwiftUI
import Moya

struct BiometryGatedScreen<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    @Binding var ownerState: API.OwnerState
    var onUnlockExpired: () -> Void
    @ViewBuilder var content: () -> Content
    
    @State private var showFacetec = false
    
    var body: some View {
        VStack {
            if let remainingUnlockedDuration = ownerState.remainingUnlockedDuration {
                UnlockedContentWrapper(
                    session: session,
                    locksAt: Date.now.addingTimeInterval(remainingUnlockedDuration),
                    ownerState: $ownerState,
                    onExpired: onUnlockExpired,
                    content: content
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white)
                .onAppear {
                    showFacetec = false
                }
            } else {
                if showFacetec {
                    FacetecAuth<API.UnlockApiResponse>(
                        session: session,
                        onReadyToUploadResults: { biomentryVerificationId, biometryData in
                            return .unlock(API.UnlockApiRequest(biometryVerificationId: biomentryVerificationId, biometryData: biometryData))
                        },
                        onSuccess: { response in
                            ownerState = response.ownerState
                        }
                    )
                } else {
                    VStack {
                        VStack {
                            Text("Vault is locked")
                            Button {
                                showFacetec = true
                            } label: {
                                Text("Unlock")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .buttonStyle(RoundedButtonStyle(tint: .dark))
                        }.padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white)
                }
            }
        }
    }
}


private struct UnlockedContentWrapper<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var locksAt: Date
    @Binding var ownerState: API.OwnerState
    var onExpired: () -> Void
    @ViewBuilder var content: () -> Content
    
    @State private var timeRemaining: TimeInterval = 0
    private let timeRemainingWhenProlongationPossible: TimeInterval = 180
    
    @State private var prolongationPromptDismissed = false
    @State private var prolongationFailed = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropLeading
        formatter.allowedUnits = [.minute]
        formatter.includesApproximationPhrase = true
        return formatter
    }
    
    var body: some View {
        let showProlongationPrompt = Binding<Bool>(
            get: {
                timeRemaining > 0
                && timeRemaining <= timeRemainingWhenProlongationPossible
                && !prolongationPromptDismissed
            },
            set: { _ in }
        )
        
        content()
        .onAppear {
            timeRemaining = locksAt.timeIntervalSinceNow
        }
        .onReceive(timer) { _ in
            if (Date.now >= locksAt) {
                onExpired()
            } else {
                timeRemaining = locksAt.timeIntervalSinceNow
            }
            if (prolongationPromptDismissed && timeRemaining > timeRemainingWhenProlongationPossible) {
                prolongationPromptDismissed = false
            }
        }
        .alert("Extend session?", isPresented: showProlongationPrompt, presenting: timeRemaining) { _ in
            VStack {
                Button("Extend") {
                    prolongationPromptDismissed = true
                    prolongUnlock()
                }
                Button("Cancel", role: .cancel) {
                    prolongationPromptDismissed = true
                }
            }
        } message: { timeRemaining in
            let formattedTime = timeRemaining > 60 ? timeFormatter.string(from: timeRemaining)?.lowercased() ?? "a few minutes" : "under a minute"
            Text("For security, your session will expire in \(formattedTime)")
        }
        .alert("Failed to extend session", isPresented: $prolongationFailed) {
            Button("OK") {
                prolongationFailed = false
            }
        }
    }
    
    private func prolongUnlock() {
        apiProvider.decodableRequest(with: session, endpoint: .prolongUnlock) { (result: Result<API.ProlongUnlockApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                ownerState = response.ownerState
            case .failure:
                prolongationFailed = true
            }
        }
    }
}

#if DEBUG
struct BiometryGatedScreen_Previews: PreviewProvider {
    static var previews: some View {
        let session = Session.sample
        
        @State var ownerState1 = API.OwnerState.guardianSetup(.init(guardians: [], threshold: 1, unlockedForSeconds: 180))
        BiometryGatedScreen(
            session: session,
            ownerState: $ownerState1,
            onUnlockExpired: {}
        ) {
            RecoveredSecretsView(
                session: .sample,
                requestedSecrets: [],
                encryptedMasterKey: Base64EncodedString(data: Data()),
                deleteRecovery: {},
                status: RecoveredSecretsView.Status.showingSecrets(
                    secrets: [
                        RecoveredSecretsView.RecoveredSecret(label: "Secret 1", secret: "Secret Phrase 1"),
                        RecoveredSecretsView.RecoveredSecret(label: "Secret 2", secret: "Secret Phrase 2"),
                    ]
                )
            )
        }
        
        @State var ownerState2 = API.OwnerState.guardianSetup(.init(guardians: [], threshold: 1, unlockedForSeconds: nil))
        BiometryGatedScreen(
            session: session,
            ownerState: $ownerState2,
            onUnlockExpired: {}
        ) {
            VStack {
                Text("test")
            }
        }
    }
}
#endif
