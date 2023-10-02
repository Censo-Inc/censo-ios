//
//  RecoveryView.swift
//  Vault
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI
import Moya

struct RecoveryView: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var threshold: UInt
    var guardians: [API.TrustedGuardian]
    var recovery: API.Recovery
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var cancelationInProgress = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        if (cancelationInProgress) {
            VStack {
                ProgressView("Canceling recovery")
                    .foregroundColor(.white)
                    .tint(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(Color.Censo.darkBlue)
        } else {
            VStack {
                
                switch (recovery) {
                case .anotherDevice:
                    Spacer()
                    
                    Text("Recovery Initiated On Another Device")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                case .thisDevice(let thisDeviceRecovery):
                    Text("Recovery Initiated")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Button {
                        cancelRecovery()
                    } label: {
                        Text("Cancel Recovery")
                            .font(.system(size: 18))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 5)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(BorderedButtonStyle(foregroundColor: .white))
                    .padding(.bottom, 10)
                    
                    let approvalsCount = thisDeviceRecovery
                        .approvals
                        .filter({ $0.approvalStatus == API.Recovery.ThisDevice.Approval.Status.approved })
                        .count
                    
                    VStack {
                        ZStack {
                            HStack {
                                Text("\(approvalsCount)")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.leading, 30)
                                
                                VStack {
                                    Spacer()
                                    Text("of")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 10)
                                }
                                
                                Text("\(threshold)")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.trailing, 30)
                            }
                            .frame(height: 62)
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.Censo.backgroundLightBlue)
                        }
                        
                        Text("required approvals reached to complete recovery")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        Text("Tap the \(Image(systemName: "square.and.arrow.up")) icon next to each of your guardians to send them the recovery link")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                    
                    List {
                        ForEach(guardians, id:\.participantId) { guardian in
                            HStack(alignment: .center, spacing: 5) {
                                VStack(spacing: 5) {
                                    HStack(spacing: 0) {
                                        Text("Status: ")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.Censo.lightGray)
                                        Text("Pending")
                                            .font(.system(size: 16).bold())
                                            .foregroundColor(Color.Censo.lightGray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(guardian.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.system(size: 24).bold())
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                if let link = URL(string: "censo-guardian://recovery/\(guardian.participantId.value)") {
                                    ShareLink(item: link,
                                              subject: Text("Censo Recovery Link for \(guardian.label)"),
                                              message: Text("Censo Recovery Link for \(guardian.label)")
                                    ){
                                        Image(systemName: "square.and.arrow.up.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.black, .white)
                                            .font(.system(size: 28))
                                    }
                                }
                            }
                            .frame(height: 64)
                            .listRowBackground(Color.Censo.backgroundLightBlue)
                            .listRowSeparatorTint(.white)
                        }
                    }
                    .background(Color.Censo.darkBlue)
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(Color.Censo.darkBlue)
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                    showingError = false
                    error = nil
                } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    func cancelRecovery() {
        cancelationInProgress = true
        apiProvider.decodableRequest(with: session, endpoint: .deleteRecovery) { (result: Result<API.DeleteRecoveryApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
            self.cancelationInProgress = false
        }
    }
}

#if DEBUG
struct RecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        let session = Session(
            deviceKey: .sample,
            userCredentials: UserCredentials(idToken: Data(), userIdentifier: "")
        )
        
        let guardians = [
            API.TrustedGuardian(
                label: "Ben",
                participantId: ParticipantId(bigInt: generateParticipantId()),
                attributes: API.GuardianStatus.Onboarded(
                    guardianEncryptedShard: Base64EncodedString(data: Data()),
                    onboardedAt: Date()
                )
            ),
            API.TrustedGuardian(
                label: "A.L.",
                participantId: ParticipantId(bigInt: generateParticipantId()),
                attributes: API.GuardianStatus.Onboarded(
                    guardianEncryptedShard: Base64EncodedString(data: Data()),
                    onboardedAt: Date()
                )
            ),
            API.TrustedGuardian(
                label: "Carlitos",
                participantId: ParticipantId(bigInt: generateParticipantId()),
                attributes: API.GuardianStatus.Onboarded(
                    guardianEncryptedShard: Base64EncodedString(data: Data()),
                    onboardedAt: Date()
                )
            ),
        ]
        
        
        LockedScreen(
            session,
            600,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            RecoveryView(
                session: session,
                threshold: 2,
                guardians: guardians,
                recovery: .thisDevice(API.Recovery.ThisDevice(
                    guid: "recovery1",
                    status: API.Recovery.Status.requested,
                    createdAt: Date(),
                    unlocksAt: Date(),
                    approvals: []
                )),
                onOwnerStateUpdated: { _ in }
            )
        }
        
        LockedScreen(
            session,
            600,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            RecoveryView(
                session: session,
                threshold: 2,
                guardians: guardians,
                recovery: .anotherDevice(API.Recovery.AnotherDevice(guid: "recovery1")),
                onOwnerStateUpdated: { _ in }
            )
        }
    }
}
#endif
