//
//  GetAuthResetApproval.swift
//  Censo
//
//  Created by Anton Onyshchenko on 25.01.24.
//

import Foundation
import SwiftUI
import Sentry
import Base32

struct GetAuthResetApproval : View {
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var authType: API.AuthType
    
    var policy: API.Policy
    var approval: API.AuthenticationReset.ThisDevice.Approval
    var approver: API.TrustedApprover
    
    var onSuccess: () -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 20) {
                    VStack {
                        Image("CensoLogoDarkBlueStacked")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding()
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .foregroundColor(.Censo.aquaBlue)
                            .background(
                                RoundedRectangle(cornerRadius: 16.0)
                            )
                        
                        Rectangle()
                            .fill(Color.Censo.darkBlue)
                            .frame(minHeight: 40)
                            .frame(maxWidth: 3, maxHeight: 80)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step 1: Share this link")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Share this link and have \(approver.label) click it or paste into their Approver app.")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                        
                        if let link = URL(string: "\(Configuration.approverUrlScheme)://auth-reset/v2/\(approver.participantId.value)/\(approval.guid)") {
                            ShareLink(
                                item: link
                            ) {
                                HStack(spacing: 0) {
                                    Image("Export")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 6)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .bold()
                                    Text("Share")
                                        .font(.headline)
                                        .foregroundColor(.Censo.aquaBlue)
                                        .padding(.trailing)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .frame(width: 128)
                                )
                            }
                            .padding(.bottom)
                            .padding(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                HStack(alignment: .top) {
                    Image("PhoneWaveform")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .padding(.horizontal, 8)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Step 2: Read Code")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        switch (approval.status) {
                        case .initial:
                            Text("Read the code that appears here and have \(approver.label) enter it in their Approver app.")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                        case .waitingForTotp, .totpVerificationFailed:
                            if let totpSecretData = base32DecodeToData(approval.totpSecret) {
                                Text("Read aloud this code and have \(approver.label) enter it into their Censo Approver app to authenticate you.")
                                    .font(.subheadline)
                                    .fontWeight(.regular)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                RotatingTotpPinView(
                                    totpSecret: totpSecretData,
                                    style: .owner
                                )
                                .padding(.top)
                            } else {
                                Text("Error generating TOTP code")
                            }
                        case .approved:
                            Text("Approved")
                                .font(.headline)
                                .onAppear {
                                    onSuccess()
                                }
                        case .rejected:
                            Text("\(approver.label) has rejected your request")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
            
            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: refreshState, isIdleTimerDisabled: true))
        .onReceive(remoteNotificationPublisher) { _ in
            refreshState()
        }
        .errorAlert(isPresented: $showingError, presenting: error)
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func refreshState() {
        ownerStateStoreController.reload()
    }
}
