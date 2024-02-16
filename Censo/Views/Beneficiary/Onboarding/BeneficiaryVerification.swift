//
//  BeneficiaryVerification.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI
import Moya
import Sentry

struct BeneficiaryVerification: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var beneficiary: API.OwnerState.Beneficiary

    @State private var currentError: Error?
    @State private var verificationCode: [Int] = []
    @State private var disabled = false

    @State private var waitingForVerification = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Enter the code")
                .font(.title2)
                .bold()
                .padding()
            
            switch beneficiary.phase {
            case .waitingForVerification:
                ProgressView(
                    label: {
                        Text("Waiting for the code to be verified...")
                    }
                )
            case .accepted:
                Text("The person you are becoming a beneficiary for will give you a 6-digit code. Enter it below.")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(20)
                
            case .verificationRejected:
                Text("That code was not verified. Please get another code and try again.")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.red)
                    .padding()
                    .onAppear {
                        disabled = false
                    }
                
            default:
                EmptyView()
            }
            
            VStack {
                VerificationCodeEntry(
                    pinInput: $verificationCode,
                    disabled: self.disabled
                )
                .onChange(of: verificationCode) { _ in
                    if (verificationCode.count == 6) {
                        submitVerificaton(code: verificationCode.map({ digit in String(digit) }).joined())
                    }
                }
            }

            if (currentError != nil) {
                Text(currentError!.localizedDescription)
                    .bold()
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
            }
        }
        .multilineTextAlignment(.center)
        .modifier(RefreshOnTimer(timer: $waitingForVerification, refresh: refreshState, isIdleTimerDisabled: true))
        
    }
    
    private func submitVerificaton(code: String) {
        guard let beneficiaryKey = try? ownerRepository.getOrCreateApproverKey(keyId: beneficiary.invitationId, entropy: beneficiary.entropy.data),
              let (timeMillis, signature) = TotpUtils.signCode(code: code, signingKey: beneficiaryKey),
              let beneficiaryPublicKey = try? beneficiaryKey.publicExternalRepresentation()
        else {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateSignature, tagValue: "BeneficiaryVerification")
            showError(CensoError.failedToCreateSignature)
            return
        }
        
        currentError = nil
        disabled = true

        ownerRepository.submitBeneficiaryVerification(
            beneficiary.invitationId,
            API.SubmitBeneficiaryVerificationApiRequest(
                beneficiaryPublicKey: beneficiaryPublicKey,
                signature: signature,
                timeMillis: timeMillis)
        ) { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func refreshState() {
        ownerStateStoreController.reload()
    }

    private func showError(_ error: Error) {
        currentError = error
        disabled = false
    }
}

#if DEBUG

extension API.OwnerState.Beneficiary.Phase.ApproverContactInfo {
    static var sample: Self {
        .init(
            participantId: .random(),
            label: "Approver One"
        )
    }
}

extension API.OwnerState.Beneficiary.Phase.TakeoverInitiated {
    static var sample: Self {
        .init(
            guid: "guid",
            approverContactInfo: [
                .sample,
                API.OwnerState.Beneficiary.Phase.ApproverContactInfo(
                    participantId: .random(),
                    label: "Approver Two"
                )
            ],
            timelockPeriodInMillis: 300000
        )
    }
}

extension API.OwnerState.Beneficiary.Phase.TakeoverRejected {
    static var sample: Self {
        .init(
            guid: "guid",
            approverContactInfo: .sample
        )
    }
}

extension API.OwnerState.Beneficiary.Phase.TakeoverTimelocked {
    static var sample: Self {
        .init(
            guid: "guid",
            unlocksAt: Date.now.addingTimeInterval(TimeInterval(172802)),
            approverContactInfo: .sample
        )
    }
}

extension API.OwnerState.Beneficiary.Phase.TakeoverVerificationPending {
    static var sample: Self {
        .init(
            guid: "guid",
            approverContactInfo: .sample
        )
    }
}

extension API.OwnerState.Beneficiary.Phase.TakeoverAvailable {
    static var sample: Self {
        .init(
            guid: "guid",
            approverContactInfo: .sample,
            ownerParticipantId: ParticipantId.random()
        )
    }
}

extension API.OwnerState.Beneficiary {
    static var sample: Self {
        .init(
            invitationId: try! BeneficiaryInvitationId(value: ""),
            entropy: Base64EncodedString(data: Data()),
            authType: .facetec,
            phase: .accepted
        )
    }
    
    static var sampleTakeoverInitiated: Self {
        .init(
            invitationId: try! BeneficiaryInvitationId(value: ""),
            entropy: Base64EncodedString(data: Data()),
            authType: .facetec,
            phase: .takeoverInitiated(.sample)
        )
    }
    
    static var sampleTakeoverVerificationPending: Self {
        .init(
            invitationId: try! BeneficiaryInvitationId(value: ""),
            entropy: Base64EncodedString(data: Data()),
            authType: .facetec,
            phase: .takeoverVerificationPending(.sample)
        )
    }
    
    static var sampleTakeoverAvailable: Self {
        .init(
            invitationId: try! BeneficiaryInvitationId(value: ""),
            entropy: Base64EncodedString(data: Data()),
            authType: .facetec,
            phase: .takeoverAvailable(.sample)
        )
    }
}
#Preview {
    LoggedInOwnerPreviewContainer {
        BeneficiaryVerification(
            beneficiary: .sample
        )
    }
}
#endif
