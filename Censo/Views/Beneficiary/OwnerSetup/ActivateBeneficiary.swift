//
//  ActivateBeneficiary.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import SwiftUI
import Sentry

struct ActivateBeneficiary : View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var beneficiary: API.Policy.Beneficiary
    var policy: API.Policy
    
    enum Mode {
        case getLive
        case activate
        case activated
    }
    
    @State private var mode: Mode = .getLive
    @State private var showingError = false
    @State private var error: Error?
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)
    
    var body: some View {
        
        switch(mode) {
        case .getLive:
            GetLive(
                name: beneficiary.label,
                isApprover: false,
                onContinue: {
                    mode = .activate
                }
            )
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        case .activated:
            Activated(
                policy: policy,
                isApprovers: false
            )
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismiss()
                }
            })
        case .activate:
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
                                .frame(minHeight: 20)
                                .frame(maxWidth: 3, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Step 1: Share Censo App")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.bottom, 3)
                            
                            Text("Share this link so \(beneficiary.label) can download the Censo app")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            ShareLink(
                                item: Configuration.ownerAppURL
                            ) {
                                HStack(spacing: 0) {
                                    Image("Export")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding([.horizontal, .vertical], 6)
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
                            .padding([.leading, .bottom])
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    HStack(alignment: .top, spacing: 20) {
                        VStack {
                            Image("CensoLogoDarkBlueStacked")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding()
                                .clipShape(RoundedRectangle(cornerRadius: 16.0))
                                .foregroundColor(.Censo.darkBlue)
                                .background(
                                    RoundedRectangle(cornerRadius: 16.0)
                                        .fill(Color.Censo.aquaBlue)
                                )
                            Rectangle()
                                .fill(Color.Censo.darkBlue)
                                .frame(minHeight: 20)
                                .frame(maxWidth: 3, maxHeight: .infinity)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Step 2: Share Invite Link")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.bottom, 3)
                            
                            Text("Share this link and have \(beneficiary.label) tap on it to open the Censo app")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let invitationId = beneficiary.invitationId {
                                ShareLink(
                                    item: invitationId.url
                                ) {
                                    HStack(spacing: 0) {
                                        Image("Export")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 6)
                                            .foregroundColor(.Censo.aquaBlue)
                                        Text("Invite")
                                            .font(.headline)
                                            .foregroundColor(.Censo.aquaBlue)
                                            .padding(.trailing)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .frame(width: 128)
                                    )
                                }
                                .padding([.leading, .bottom])
                                .disabled(beneficiary.disableInvitationShare)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    
                    HStack(alignment: .top) {
                        Image("PhoneWaveform")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .padding(.horizontal, 8)

                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Step 3: Read Code")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.bottom, 3)
                            
                            
                            if let deviceEncryptedTotpSecret = beneficiary.deviceEncryptedTotpSecret,
                               let totpSecret = try? ownerRepository.deviceKey.decrypt(data: deviceEncryptedTotpSecret.data) {
                                RotatingTotpPinView(
                                    totpSecret: totpSecret,
                                    style: .owner
                                )
                            } else if beneficiary.isActivated {
                                Text("\(beneficiary.label) is now activated!")
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("Read code that appears here and have \(beneficiary.label) enter it in the Censo app")
                                    .font(.subheadline)
                                    .fontWeight(.regular)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.bottom)
                }
                .padding(.horizontal)
                
                Spacer()

                VStack(spacing: 0) {
                    Divider()
                        .padding(.bottom)

                    BeneficiaryPill(
                        beneficiary: beneficiary,
                        onVerificationSubmitted: activateBeneficiary,
                        onActivated: {
                            mode = .activated
                        }
                    )
                    .padding(.bottom)
                }
                .padding([.leading, .trailing], 32)
            }
            .padding([.top], 24)
            .navigationTitle(Text("Add beneficiary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        mode = .getLive
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
            .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: refreshState, isIdleTimerDisabled: true))
            .onReceive(remoteNotificationPublisher) { _ in
                refreshState()
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func refreshState() {
        ownerStateStoreController.reload()
    }
    
    private func activateBeneficiary(status: API.Policy.Beneficiary.Status.VerificationSubmitted) {
        guard let ownerEntropy = policy.ownerEntropy else {
            showError(CensoError.invalidEntropy)
            return
        }
        
        var confirmationSucceeded = false
        do {
            confirmationSucceeded = try verifyBeneficiarySignature(status: status)
        } catch {
            confirmationSucceeded = false
        }
        
        guard let ownerEntropy = policy.ownerEntropy else {
            showError(CensoError.invalidEntropy)
            return
        }

        if confirmationSucceeded {
            do {
                
                let ownerApproverKey = try ownerRepository.getOrCreateApproverKey(keyId: policy.owner!.participantId, entropy: ownerEntropy.data)
                let ownerApproverKeyBytes = try ownerApproverKey.privateKeyRaw()
                SentrySDK.addCrumb(category: "Beneficiary setup", message: "private key step")
                let beneficiaryEncryptionKey = try EncryptionKey
                    .generateFromPublicExternalRepresentation(base58PublicKey: status.beneficiaryPublicKey)
                let encryptedOwnerKeyBytes = try beneficiaryEncryptionKey.encrypt(data: ownerApproverKeyBytes).data
                SentrySDK.addCrumb(category: "Beneficiary setup", message: "encryption step")
                
                let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
                guard let timeMillisData = String(timeMillis).data(using: .utf8),
                      let signature = try? ownerApproverKey.signature(for: status.beneficiaryPublicKey.data + timeMillisData) else {
                    throw CensoError.failedToCreateSignature
                }
                SentrySDK.addCrumb(category: "Beneficiary setup", message: "signature step")
        
                ownerRepository.activateBeneficiary(
                    API.ActivateBeneficiaryApiRequest(
                        keyConfirmationSignature: signature,
                        keyConfirmationTimeMillis: timeMillis,
                        encryptedKeys: try status.approverPublicKeys.map({
                            let encryptedKey = try EncryptionKey
                                .generateFromPublicExternalRepresentation(base58PublicKey: $0.publicKey).encrypt(data: encryptedOwnerKeyBytes)
                            SentrySDK.addCrumb(category: "Beneficiary setup", message: "approver encryption step")
                            return API.BeneficiaryEncryptedKey(
                                participantId: $0.participantId,
                                encryptedKey: encryptedKey
                            )
                        })
                    )
                ) { result in
                    switch result {
                    case .success(let response):
                        ownerStateStoreController.replace(response.ownerState)
                    case .failure:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            activateBeneficiary(status: status) // keep trying
                        }
                    }
                }
            } catch {
                showError(error)
                SentrySDK.captureWithTag(error: error, tagValue: "BeneficiaryVerification")
            }
        } else {
            rejectBeneficiaryVerification()
        }
    }

    private func verifyBeneficiarySignature(status: API.Policy.Beneficiary.Status.VerificationSubmitted) throws -> Bool {
        guard let totpSecret = try? ownerRepository.deviceKey.decrypt(data: status.deviceEncryptedTotpSecret.data),
              let timeMillisBytes = String(status.timeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.beneficiaryPublicKey) else {
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
    
    private func rejectBeneficiaryVerification() {
        ownerRepository.rejectBeneficiaryVerification() { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    rejectBeneficiaryVerification() // keep trying
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        VStack {}
            .sheet(isPresented: Binding.constant(true), content: {
                NavigationView {
                    ActivateBeneficiary(
                        beneficiary: .sampleAccepted,
                        policy: .sample2ApproversAndBeneficiary
                    )
                }
            })
    }
}
#endif
