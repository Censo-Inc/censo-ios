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
    var encryptedSecrets: [API.VaultSecret]
    var encryptedMasterKey: Base64EncodedString
    var recovery: API.Recovery
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var cancelationInProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        NavigationStack {
            if (cancelationInProgress) {
                VStack {
                    ProgressView("Canceling access request...")
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
                            .padding(.bottom, 5)
                        
                        RecoveryExpirationCountDown(
                            expiresAt: thisDeviceRecovery.expiresAt,
                            onTimeout: cancelRecovery
                        )
                        .padding(.bottom, 10)
                        
                        Button {
                            cancelRecovery()
                        } label: {
                            Text("Cancel Recovery")
                                .font(.system(size: 18))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 5)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(BorderedButtonStyle(tint: .light))
                        .padding(.bottom, 10)
                        
                        let approvalsCount = thisDeviceRecovery
                            .approvals
                            .filter({ $0.status == API.Recovery.ThisDevice.Approval.Status.approved })
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
                                    .fill(.white.opacity(0.05))
                            }
                            
                            Text("required approvals reached to complete recovery")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                        
                        if thisDeviceRecovery.status == .requested {
                            Text("Tap the \(Image(systemName: "square.and.arrow.up")) icon next to each of your approvers to send them the recovery link")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 20)
                            
                            List {
                                ForEach(guardians, id:\.participantId) { guardian in
                                    if let approval = thisDeviceRecovery.approvals.first(where: { $0.participantId == guardian.participantId }) {
                                        RecoveryApproverRow(
                                            session: session,
                                            guardian: guardian,
                                            approval: approval,
                                            reloadUser: reloadUser,
                                            onOwnerStateUpdated: onOwnerStateUpdated
                                        )
                                    }
                                }
                            }
                            .background(Color.Censo.darkBlue)
                            .scrollContentBackground(.hidden)
                        } else {
                            Spacer()
                            
                            let isTimelocked = thisDeviceRecovery.status == .timelocked
                            
                            NavigationLink {
                                RecoveredSecretsView(
                                    session: session,
                                    requestedSecrets: encryptedSecrets,
                                    encryptedMasterKey: encryptedMasterKey,
                                    deleteRecovery: cancelRecovery
                                )
                            } label: {
                                Text("Access Seed Phrases")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 44)
                                    .foregroundColor(Color.Censo.darkBlue)
                            }
                            .padding(.horizontal)
                            .buttonStyle(FilledButtonStyle(tint: .light))
                            .disabled(isTimelocked)
                            
                            var formatter: DateComponentsFormatter {
                                let formatter = DateComponentsFormatter()
                                formatter.unitsStyle = .full
                                formatter.zeroFormattingBehavior = .dropLeading
                                formatter.allowedUnits = [.day, .hour, .minute]
                                return formatter
                            }
                            let unlocksIn = thisDeviceRecovery.unlocksAt.timeIntervalSinceNow
                            
                            if isTimelocked {
                                let formattedTime = unlocksIn >= 120 ? formatter.string(from: unlocksIn) : "under 2 minutes"
                                Text(formattedTime != nil ? "Available in \(formattedTime!)" : "")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Color.Censo.darkBlue)
                .onReceive(remoteNotificationPublisher) { _ in
                    reloadUser()
                }
                .onReceive(refreshStatePublisher) { _ in
                    reloadUser()
                }
                .onDisappear() {
                    refreshStatePublisher.upstream.connect().cancel()
                }
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
    }
    
    private func cancelRecovery() {
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
    
    private func reloadUser() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdated(user.ownerState)
            default:
                break
            }
        }
    }
}

#if DEBUG
extension API.TrustedGuardian {
    static var sample: Self {
        .init(
            label: "Ben",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample2: Self {
        .init(
            label: "Brendan",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample3: Self {
        .init(
            label: "Ievgen",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample4: Self {
        .init(
            label: "Ata",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample5: Self {
        .init(
            label: "Sam",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
}

struct RecoveryView_Previews: PreviewProvider {
    static var previews: some View {
        let guardians = [
            API.TrustedGuardian.sample,
            API.TrustedGuardian.sample2,
            API.TrustedGuardian.sample3,
            API.TrustedGuardian.sample4,
            API.TrustedGuardian.sample5
        ]
        let today = Date()
        let in2Minutes30seconds = Calendar.current.date(byAdding: .second, value: 120, to: today)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)
        
        RecoveryView(
            session: .sample,
            threshold: 2,
            guardians: guardians,
            encryptedSecrets: [],
            encryptedMasterKey: Base64EncodedString(data: Data()),
            recovery: .thisDevice(API.Recovery.ThisDevice(
                guid: "recovery1",
                status: API.Recovery.Status.requested,
                createdAt: today,
                unlocksAt: tomorrow!,
                expiresAt: tomorrow!,
                approvals: [
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[0].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.initial
                    ),
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[1].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.waitingForVerification
                    ),
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[2].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.waitingForApproval
                    ),
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[3].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.approved
                    ),
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[4].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.rejected
                    )
                ]
            )),
            onOwnerStateUpdated: { _ in }
        )
        
        RecoveryView(
            session: .sample,
            threshold: 2,
            guardians: guardians,
            encryptedSecrets: [],
            encryptedMasterKey: Base64EncodedString(data: Data()),
            recovery: .thisDevice(API.Recovery.ThisDevice(
                guid: "recovery1",
                status: API.Recovery.Status.timelocked,
                createdAt: today,
                unlocksAt: in2Minutes30seconds!,
                expiresAt: tomorrow!,
                approvals: [
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[0].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.approved
                    ),
                    API.Recovery.ThisDevice.Approval(
                        participantId: guardians[1].participantId,
                        status: API.Recovery.ThisDevice.Approval.Status.approved
                    ),
                ]
            )),
            onOwnerStateUpdated: { _ in }
        )
        
        RecoveryView(
            session: .sample,
            threshold: 2,
            guardians: guardians,
            encryptedSecrets: [],
            encryptedMasterKey: Base64EncodedString(data: Data()),
            recovery: .anotherDevice(API.Recovery.AnotherDevice(guid: "recovery1")),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
